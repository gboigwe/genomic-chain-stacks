;; clinical-trial - Clarity 4
;; Clinical trial management and tracking

(define-constant ERR-TRIAL-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-PHASE (err u102))
(define-constant ERR-ENROLLMENT-CLOSED (err u103))
(define-constant ERR-ALREADY-ENROLLED (err u104))

(define-map clinical-trials uint
  {
    sponsor: principal,
    title: (string-utf8 200),
    nct-id: (string-ascii 50),
    start-date: uint,
    end-date: (optional uint),
    phase: (string-ascii 20),
    status: (string-ascii 20),
    enrollment-target: uint,
    enrollment-current: uint,
    primary-endpoint: (string-utf8 300),
    is-active: bool
  }
)

(define-map trial-participants uint
  {
    trial-id: uint,
    participant: principal,
    enrollment-date: uint,
    group-assignment: (string-ascii 50),
    status: (string-ascii 20),
    completion-date: (optional uint),
    withdrawal-reason: (optional (string-utf8 200))
  }
)

(define-map trial-outcomes uint
  {
    trial-id: uint,
    participant-id: uint,
    outcome-type: (string-ascii 50),
    measurement: (string-utf8 200),
    recorded-at: uint,
    recorded-by: principal,
    is-primary: bool
  }
)

(define-map trial-sites uint
  {
    trial-id: uint,
    site-name: (string-utf8 100),
    principal-investigator: principal,
    location: (string-utf8 200),
    enrollment-capacity: uint,
    is-active: bool,
    activated-at: uint
  }
)

(define-map adverse-events uint
  {
    trial-id: uint,
    participant-id: uint,
    event-description: (string-utf8 500),
    severity: (string-ascii 20),
    causality: (string-ascii 50),
    reported-at: uint,
    reported-by: principal,
    resolution: (optional (string-utf8 300))
  }
)

(define-map protocol-amendments uint
  {
    trial-id: uint,
    amendment-number: uint,
    description: (string-utf8 500),
    rationale: (string-utf8 500),
    approved-by: principal,
    approved-at: uint,
    effective-date: uint
  }
)

(define-data-var trial-counter uint u0)
(define-data-var participant-counter uint u0)
(define-data-var outcome-counter uint u0)
(define-data-var site-counter uint u0)
(define-data-var event-counter uint u0)
(define-data-var amendment-counter uint u0)

(define-public (register-trial
    (title (string-utf8 200))
    (nct-id (string-ascii 50))
    (start-date uint)
    (phase (string-ascii 20))
    (enrollment-target uint)
    (primary-endpoint (string-utf8 300)))
  (let ((trial-id (+ (var-get trial-counter) u1)))
    (map-set clinical-trials trial-id
      {
        sponsor: tx-sender,
        title: title,
        nct-id: nct-id,
        start-date: start-date,
        end-date: none,
        phase: phase,
        status: "recruiting",
        enrollment-target: enrollment-target,
        enrollment-current: u0,
        primary-endpoint: primary-endpoint,
        is-active: true
      })
    (var-set trial-counter trial-id)
    (ok trial-id)))

(define-public (enroll-participant
    (trial-id uint)
    (participant principal)
    (group-assignment (string-ascii 50)))
  (let ((trial (unwrap! (map-get? clinical-trials trial-id) ERR-TRIAL-NOT-FOUND))
        (participant-id (+ (var-get participant-counter) u1)))
    (asserts! (get is-active trial) ERR-ENROLLMENT-CLOSED)
    (asserts! (< (get enrollment-current trial) (get enrollment-target trial)) ERR-ENROLLMENT-CLOSED)
    (map-set trial-participants participant-id
      {
        trial-id: trial-id,
        participant: participant,
        enrollment-date: stacks-block-time,
        group-assignment: group-assignment,
        status: "enrolled",
        completion-date: none,
        withdrawal-reason: none
      })
    (map-set clinical-trials trial-id
      (merge trial { enrollment-current: (+ (get enrollment-current trial) u1) }))
    (var-set participant-counter participant-id)
    (ok participant-id)))

(define-public (record-outcome
    (trial-id uint)
    (participant-id uint)
    (outcome-type (string-ascii 50))
    (measurement (string-utf8 200))
    (is-primary bool))
  (let ((outcome-id (+ (var-get outcome-counter) u1)))
    (asserts! (is-some (map-get? clinical-trials trial-id)) ERR-TRIAL-NOT-FOUND)
    (map-set trial-outcomes outcome-id
      {
        trial-id: trial-id,
        participant-id: participant-id,
        outcome-type: outcome-type,
        measurement: measurement,
        recorded-at: stacks-block-time,
        recorded-by: tx-sender,
        is-primary: is-primary
      })
    (var-set outcome-counter outcome-id)
    (ok outcome-id)))

(define-public (register-site
    (trial-id uint)
    (site-name (string-utf8 100))
    (principal-investigator principal)
    (location (string-utf8 200))
    (enrollment-capacity uint))
  (let ((site-id (+ (var-get site-counter) u1)))
    (asserts! (is-some (map-get? clinical-trials trial-id)) ERR-TRIAL-NOT-FOUND)
    (map-set trial-sites site-id
      {
        trial-id: trial-id,
        site-name: site-name,
        principal-investigator: principal-investigator,
        location: location,
        enrollment-capacity: enrollment-capacity,
        is-active: true,
        activated-at: stacks-block-time
      })
    (var-set site-counter site-id)
    (ok site-id)))

(define-public (report-adverse-event
    (trial-id uint)
    (participant-id uint)
    (event-description (string-utf8 500))
    (severity (string-ascii 20))
    (causality (string-ascii 50)))
  (let ((event-id (+ (var-get event-counter) u1)))
    (map-set adverse-events event-id
      {
        trial-id: trial-id,
        participant-id: participant-id,
        event-description: event-description,
        severity: severity,
        causality: causality,
        reported-at: stacks-block-time,
        reported-by: tx-sender,
        resolution: none
      })
    (var-set event-counter event-id)
    (ok event-id)))

(define-public (amend-protocol
    (trial-id uint)
    (amendment-number uint)
    (description (string-utf8 500))
    (rationale (string-utf8 500))
    (effective-date uint))
  (let ((trial (unwrap! (map-get? clinical-trials trial-id) ERR-TRIAL-NOT-FOUND))
        (amendment-id (+ (var-get amendment-counter) u1)))
    (asserts! (is-eq tx-sender (get sponsor trial)) ERR-NOT-AUTHORIZED)
    (map-set protocol-amendments amendment-id
      {
        trial-id: trial-id,
        amendment-number: amendment-number,
        description: description,
        rationale: rationale,
        approved-by: tx-sender,
        approved-at: stacks-block-time,
        effective-date: effective-date
      })
    (var-set amendment-counter amendment-id)
    (ok amendment-id)))

(define-public (update-trial-status
    (trial-id uint)
    (new-status (string-ascii 20)))
  (let ((trial (unwrap! (map-get? clinical-trials trial-id) ERR-TRIAL-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get sponsor trial)) ERR-NOT-AUTHORIZED)
    (ok (map-set clinical-trials trial-id
      (merge trial { status: new-status })))))

(define-read-only (get-trial (trial-id uint))
  (ok (map-get? clinical-trials trial-id)))

(define-read-only (get-participant (participant-id uint))
  (ok (map-get? trial-participants participant-id)))

(define-read-only (get-outcome (outcome-id uint))
  (ok (map-get? trial-outcomes outcome-id)))

(define-read-only (get-site (site-id uint))
  (ok (map-get? trial-sites site-id)))

(define-read-only (get-adverse-event (event-id uint))
  (ok (map-get? adverse-events event-id)))

(define-read-only (get-amendment (amendment-id uint))
  (ok (map-get? protocol-amendments amendment-id)))

(define-read-only (validate-sponsor (sponsor principal))
  (principal-destruct? sponsor))

(define-read-only (format-trial-id (trial-id uint))
  (ok (int-to-ascii trial-id)))

(define-read-only (parse-trial-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
