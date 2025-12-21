;; dispute-resolution - Clarity 4
;; Decentralized dispute resolution for platform conflicts

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-DISPUTE-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-RESOLVED (err u102))
(define-constant ERR-INVALID-VOTE (err u103))
(define-constant ERR-VOTING-CLOSED (err u104))

(define-map disputes uint
  {
    plaintiff: principal,
    defendant: principal,
    dispute-type: (string-ascii 50),
    description: (string-utf8 500),
    evidence-hash: (buff 64),
    filed-at: uint,
    status: (string-ascii 20),
    resolution: (optional (string-utf8 500)),
    resolved-at: (optional uint)
  }
)

(define-map arbitrators principal
  {
    name: (string-utf8 100),
    specialization: (string-ascii 50),
    cases-resolved: uint,
    reputation-score: uint,
    is-active: bool
  }
)

(define-map dispute-votes { dispute-id: uint, arbitrator: principal }
  {
    vote: (string-ascii 20),
    reasoning: (string-utf8 500),
    voted-at: uint
  }
)

(define-map vote-tallies uint
  {
    votes-for-plaintiff: uint,
    votes-for-defendant: uint,
    total-votes: uint,
    voting-deadline: uint
  }
)

(define-map evidence-submissions uint
  {
    dispute-id: uint,
    submitter: principal,
    evidence-hash: (buff 64),
    evidence-type: (string-ascii 50),
    submitted-at: uint
  }
)

(define-data-var dispute-counter uint u0)
(define-data-var evidence-counter uint u0)
(define-data-var voting-period uint u604800) ;; 7 days

(define-public (file-dispute
    (defendant principal)
    (dispute-type (string-ascii 50))
    (description (string-utf8 500))
    (evidence-hash (buff 64)))
  (let ((dispute-id (+ (var-get dispute-counter) u1)))
    (map-set disputes dispute-id
      {
        plaintiff: tx-sender,
        defendant: defendant,
        dispute-type: dispute-type,
        description: description,
        evidence-hash: evidence-hash,
        filed-at: stacks-block-time,
        status: "open",
        resolution: none,
        resolved-at: none
      })
    (map-set vote-tallies dispute-id
      {
        votes-for-plaintiff: u0,
        votes-for-defendant: u0,
        total-votes: u0,
        voting-deadline: (+ stacks-block-time (var-get voting-period))
      })
    (var-set dispute-counter dispute-id)
    (ok dispute-id)))

(define-public (register-arbitrator
    (name (string-utf8 100))
    (specialization (string-ascii 50)))
  (ok (map-set arbitrators tx-sender
    {
      name: name,
      specialization: specialization,
      cases-resolved: u0,
      reputation-score: u50,
      is-active: true
    })))

(define-public (cast-vote
    (dispute-id uint)
    (vote (string-ascii 20))
    (reasoning (string-utf8 500)))
  (let ((dispute (unwrap! (map-get? disputes dispute-id) ERR-DISPUTE-NOT-FOUND))
        (arbitrator (unwrap! (map-get? arbitrators tx-sender) ERR-NOT-AUTHORIZED))
        (tally (unwrap! (map-get? vote-tallies dispute-id) ERR-DISPUTE-NOT-FOUND)))
    (asserts! (get is-active arbitrator) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status dispute) "open") ERR-ALREADY-RESOLVED)
    (asserts! (< stacks-block-time (get voting-deadline tally)) ERR-VOTING-CLOSED)
    (map-set dispute-votes { dispute-id: dispute-id, arbitrator: tx-sender }
      {
        vote: vote,
        reasoning: reasoning,
        voted-at: stacks-block-time
      })
    (update-vote-tally dispute-id vote)
    (ok true)))

(define-public (submit-evidence
    (dispute-id uint)
    (evidence-hash (buff 64))
    (evidence-type (string-ascii 50)))
  (let ((dispute (unwrap! (map-get? disputes dispute-id) ERR-DISPUTE-NOT-FOUND))
        (evidence-id (+ (var-get evidence-counter) u1)))
    (asserts! (or (is-eq tx-sender (get plaintiff dispute))
                  (is-eq tx-sender (get defendant dispute))) ERR-NOT-AUTHORIZED)
    (map-set evidence-submissions evidence-id
      {
        dispute-id: dispute-id,
        submitter: tx-sender,
        evidence-hash: evidence-hash,
        evidence-type: evidence-type,
        submitted-at: stacks-block-time
      })
    (var-set evidence-counter evidence-id)
    (ok evidence-id)))

(define-public (resolve-dispute
    (dispute-id uint)
    (resolution (string-utf8 500)))
  (let ((dispute (unwrap! (map-get? disputes dispute-id) ERR-DISPUTE-NOT-FOUND))
        (tally (unwrap! (map-get? vote-tallies dispute-id) ERR-DISPUTE-NOT-FOUND)))
    (asserts! (>= stacks-block-time (get voting-deadline tally)) ERR-VOTING-CLOSED)
    (asserts! (is-eq (get status dispute) "open") ERR-ALREADY-RESOLVED)
    (ok (map-set disputes dispute-id
      (merge dispute {
        status: "resolved",
        resolution: (some resolution),
        resolved-at: (some stacks-block-time)
      })))))

(define-private (update-vote-tally (dispute-id uint) (vote (string-ascii 20)))
  (let ((tally (unwrap! (map-get? vote-tallies dispute-id) ERR-DISPUTE-NOT-FOUND)))
    (map-set vote-tallies dispute-id
      (merge tally {
        votes-for-plaintiff: (if (is-eq vote "plaintiff")
                                (+ (get votes-for-plaintiff tally) u1)
                                (get votes-for-plaintiff tally)),
        votes-for-defendant: (if (is-eq vote "defendant")
                                (+ (get votes-for-defendant tally) u1)
                                (get votes-for-defendant tally)),
        total-votes: (+ (get total-votes tally) u1)
      }))
    (ok true)))

(define-read-only (get-dispute (dispute-id uint))
  (ok (map-get? disputes dispute-id)))

(define-read-only (get-arbitrator (arbitrator principal))
  (ok (map-get? arbitrators arbitrator)))

(define-read-only (get-vote (dispute-id uint) (arbitrator principal))
  (ok (map-get? dispute-votes { dispute-id: dispute-id, arbitrator: arbitrator })))

(define-read-only (get-vote-tally (dispute-id uint))
  (ok (map-get? vote-tallies dispute-id)))

(define-read-only (get-evidence (evidence-id uint))
  (ok (map-get? evidence-submissions evidence-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-dispute-id (dispute-id uint))
  (ok (int-to-ascii dispute-id)))

(define-read-only (parse-dispute-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
