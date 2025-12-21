;; federated-learning - Clarity 4
;; Federated learning coordination for privacy-preserving genomic ML

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-SESSION-NOT-FOUND (err u101))
(define-constant ERR-INVALID-CONTRIBUTION (err u102))
(define-constant ERR-SESSION-CLOSED (err u103))

(define-map learning-sessions uint
  {
    coordinator: principal,
    model-hash: (buff 64),
    min-participants: uint,
    current-participants: uint,
    target-accuracy: uint,
    current-accuracy: uint,
    started-at: uint,
    deadline: uint,
    is-active: bool,
    aggregation-round: uint
  }
)

(define-map participant-contributions { session-id: uint, participant: principal }
  {
    model-update-hash: (buff 64),
    contribution-round: uint,
    data-samples: uint,
    local-accuracy: uint,
    submitted-at: uint,
    is-verified: bool
  }
)

(define-map participant-rewards principal
  {
    total-contributions: uint,
    total-rewards: uint,
    reputation-score: uint,
    last-contribution: uint
  }
)

(define-map aggregation-results uint
  {
    session-id: uint,
    round: uint,
    aggregated-model-hash: (buff 64),
    participants-count: uint,
    accuracy-improvement: uint,
    aggregated-at: uint,
    aggregator: principal
  }
)

(define-data-var session-counter uint u0)
(define-data-var aggregation-counter uint u0)
(define-data-var min-data-samples uint u100)

(define-public (create-learning-session
    (model-hash (buff 64))
    (min-participants uint)
    (target-accuracy uint)
    (duration uint))
  (let ((session-id (+ (var-get session-counter) u1)))
    (map-set learning-sessions session-id
      {
        coordinator: tx-sender,
        model-hash: model-hash,
        min-participants: min-participants,
        current-participants: u0,
        target-accuracy: target-accuracy,
        current-accuracy: u0,
        started-at: stacks-block-time,
        deadline: (+ stacks-block-time duration),
        is-active: true,
        aggregation-round: u0
      })
    (var-set session-counter session-id)
    (ok session-id)))

(define-public (submit-contribution
    (session-id uint)
    (model-update-hash (buff 64))
    (data-samples uint)
    (local-accuracy uint))
  (let ((session (unwrap! (map-get? learning-sessions session-id) ERR-SESSION-NOT-FOUND)))
    (asserts! (get is-active session) ERR-SESSION-CLOSED)
    (asserts! (< stacks-block-time (get deadline session)) ERR-SESSION-CLOSED)
    (asserts! (>= data-samples (var-get min-data-samples)) ERR-INVALID-CONTRIBUTION)
    (map-set participant-contributions { session-id: session-id, participant: tx-sender }
      {
        model-update-hash: model-update-hash,
        contribution-round: (get aggregation-round session),
        data-samples: data-samples,
        local-accuracy: local-accuracy,
        submitted-at: stacks-block-time,
        is-verified: false
      })
    (map-set learning-sessions session-id
      (merge session { current-participants: (+ (get current-participants session) u1) }))
    (update-participant-stats tx-sender)
    (ok true)))

(define-public (aggregate-models
    (session-id uint)
    (aggregated-model-hash (buff 64))
    (accuracy-improvement uint))
  (let ((session (unwrap! (map-get? learning-sessions session-id) ERR-SESSION-NOT-FOUND))
        (aggregation-id (+ (var-get aggregation-counter) u1)))
    (asserts! (is-eq tx-sender (get coordinator session)) ERR-NOT-AUTHORIZED)
    (asserts! (get is-active session) ERR-SESSION-CLOSED)
    (map-set aggregation-results aggregation-id
      {
        session-id: session-id,
        round: (get aggregation-round session),
        aggregated-model-hash: aggregated-model-hash,
        participants-count: (get current-participants session),
        accuracy-improvement: accuracy-improvement,
        aggregated-at: stacks-block-time,
        aggregator: tx-sender
      })
    (map-set learning-sessions session-id
      (merge session {
        aggregation-round: (+ (get aggregation-round session) u1),
        current-accuracy: (+ (get current-accuracy session) accuracy-improvement),
        current-participants: u0
      }))
    (var-set aggregation-counter aggregation-id)
    (ok aggregation-id)))

(define-public (verify-contribution (session-id uint) (participant principal))
  (let ((contribution (unwrap! (map-get? participant-contributions { session-id: session-id, participant: participant }) ERR-INVALID-CONTRIBUTION)))
    (ok (map-set participant-contributions { session-id: session-id, participant: participant }
      (merge contribution { is-verified: true })))))

(define-public (close-session (session-id uint))
  (let ((session (unwrap! (map-get? learning-sessions session-id) ERR-SESSION-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get coordinator session)) ERR-NOT-AUTHORIZED)
    (ok (map-set learning-sessions session-id
      (merge session { is-active: false })))))

(define-private (update-participant-stats (participant principal))
  (let ((stats (default-to
                 { total-contributions: u0, total-rewards: u0, reputation-score: u50, last-contribution: u0 }
                 (map-get? participant-rewards participant))))
    (map-set participant-rewards participant
      {
        total-contributions: (+ (get total-contributions stats) u1),
        total-rewards: (get total-rewards stats),
        reputation-score: (+ (get reputation-score stats) u1),
        last-contribution: stacks-block-time
      })
    true))

(define-read-only (get-session (session-id uint))
  (ok (map-get? learning-sessions session-id)))

(define-read-only (get-contribution (session-id uint) (participant principal))
  (ok (map-get? participant-contributions { session-id: session-id, participant: participant })))

(define-read-only (get-participant-stats (participant principal))
  (ok (map-get? participant-rewards participant)))

(define-read-only (get-aggregation-result (aggregation-id uint))
  (ok (map-get? aggregation-results aggregation-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-session-id (session-id uint))
  (ok (int-to-ascii session-id)))

(define-read-only (parse-session-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
