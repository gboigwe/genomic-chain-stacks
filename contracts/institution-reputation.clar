;; institution-reputation - Clarity 4
;; Institution reputation scoring and trust management

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSTITUTION-NOT-FOUND (err u101))
(define-constant ERR-INVALID-RATING (err u102))
(define-constant ERR-ALREADY-RATED (err u103))

(define-map institutions principal
  {
    institution-name: (string-utf8 200),
    institution-type: (string-ascii 50),
    registration-number: (string-ascii 100),
    reputation-score: uint,
    total-ratings: uint,
    verified-status: bool,
    registered-at: uint
  }
)

(define-map reputation-ratings { institution: principal, rater: principal }
  {
    rating-score: uint,
    rating-category: (string-ascii 50),
    comment: (string-utf8 500),
    rated-at: uint,
    is-verified: bool
  }
)

(define-map performance-metrics principal
  {
    compliance-score: uint,
    data-security-score: uint,
    response-time-score: uint,
    patient-satisfaction: uint,
    last-updated: uint
  }
)

(define-map accreditation-records uint
  {
    institution: principal,
    accrediting-body: (string-utf8 100),
    accreditation-level: (string-ascii 50),
    score: uint,
    issued-date: uint,
    expiry-date: uint
  }
)

(define-map incident-reports uint
  {
    institution: principal,
    incident-type: (string-ascii 50),
    severity: uint,
    reported-by: principal,
    reported-at: uint,
    resolution-status: (string-ascii 20),
    impact-on-reputation: uint
  }
)

(define-data-var accreditation-counter uint u0)
(define-data-var incident-counter uint u0)
(define-data-var base-reputation-score uint u50)

(define-public (register-institution
    (institution-name (string-utf8 200))
    (institution-type (string-ascii 50))
    (registration-number (string-ascii 100)))
  (ok (map-set institutions tx-sender
    {
      institution-name: institution-name,
      institution-type: institution-type,
      registration-number: registration-number,
      reputation-score: (var-get base-reputation-score),
      total-ratings: u0,
      verified-status: false,
      registered-at: stacks-block-time
    })))

(define-public (submit-rating
    (institution principal)
    (rating-score uint)
    (rating-category (string-ascii 50))
    (comment (string-utf8 500)))
  (let ((inst-data (unwrap! (map-get? institutions institution) ERR-INSTITUTION-NOT-FOUND)))
    (asserts! (<= rating-score u100) ERR-INVALID-RATING)
    (asserts! (is-none (map-get? reputation-ratings { institution: institution, rater: tx-sender })) ERR-ALREADY-RATED)
    (map-set reputation-ratings { institution: institution, rater: tx-sender }
      {
        rating-score: rating-score,
        rating-category: rating-category,
        comment: comment,
        rated-at: stacks-block-time,
        is-verified: false
      })
    (update-reputation-score institution rating-score)
    (ok true)))

(define-public (update-performance-metrics
    (compliance-score uint)
    (data-security-score uint)
    (response-time-score uint)
    (patient-satisfaction uint))
  (let ((inst-data (unwrap! (map-get? institutions tx-sender) ERR-INSTITUTION-NOT-FOUND)))
    (ok (map-set performance-metrics tx-sender
      {
        compliance-score: compliance-score,
        data-security-score: data-security-score,
        response-time-score: response-time-score,
        patient-satisfaction: patient-satisfaction,
        last-updated: stacks-block-time
      }))))

(define-public (add-accreditation
    (accrediting-body (string-utf8 100))
    (accreditation-level (string-ascii 50))
    (score uint)
    (expiry-date uint))
  (let ((accred-id (+ (var-get accreditation-counter) u1))
        (inst-data (unwrap! (map-get? institutions tx-sender) ERR-INSTITUTION-NOT-FOUND)))
    (map-set accreditation-records accred-id
      {
        institution: tx-sender,
        accrediting-body: accrediting-body,
        accreditation-level: accreditation-level,
        score: score,
        issued-date: stacks-block-time,
        expiry-date: expiry-date
      })
    (var-set accreditation-counter accred-id)
    (ok accred-id)))

(define-public (report-incident
    (institution principal)
    (incident-type (string-ascii 50))
    (severity uint))
  (let ((incident-id (+ (var-get incident-counter) u1))
        (inst-data (unwrap! (map-get? institutions institution) ERR-INSTITUTION-NOT-FOUND)))
    (map-set incident-reports incident-id
      {
        institution: institution,
        incident-type: incident-type,
        severity: severity,
        reported-by: tx-sender,
        reported-at: stacks-block-time,
        resolution-status: "open",
        impact-on-reputation: severity
      })
    (adjust-reputation-for-incident institution severity)
    (var-set incident-counter incident-id)
    (ok incident-id)))

(define-public (verify-institution (institution principal))
  (let ((inst-data (unwrap! (map-get? institutions institution) ERR-INSTITUTION-NOT-FOUND)))
    (ok (map-set institutions institution
      (merge inst-data { verified-status: true })))))

(define-private (update-reputation-score (institution principal) (new-rating uint))
  (let ((inst-data (unwrap! (map-get? institutions institution) ERR-INSTITUTION-NOT-FOUND))
        (current-score (get reputation-score inst-data))
        (total-ratings (get total-ratings inst-data))
        (new-total-ratings (+ total-ratings u1))
        (new-score (/ (+ (* current-score total-ratings) new-rating) new-total-ratings)))
    (map-set institutions institution
      (merge inst-data {
        reputation-score: new-score,
        total-ratings: new-total-ratings
      }))
    (ok true)))

(define-private (adjust-reputation-for-incident (institution principal) (severity uint))
  (let ((inst-data (unwrap! (map-get? institutions institution) ERR-INSTITUTION-NOT-FOUND))
        (penalty (/ severity u2))
        (new-score (if (>= (get reputation-score inst-data) penalty)
                      (- (get reputation-score inst-data) penalty)
                      u0)))
    (map-set institutions institution
      (merge inst-data { reputation-score: new-score }))
    (ok true)))

(define-read-only (get-institution (institution principal))
  (ok (map-get? institutions institution)))

(define-read-only (get-rating (institution principal) (rater principal))
  (ok (map-get? reputation-ratings { institution: institution, rater: rater })))

(define-read-only (get-performance-metrics (institution principal))
  (ok (map-get? performance-metrics institution)))

(define-read-only (get-accreditation (accreditation-id uint))
  (ok (map-get? accreditation-records accreditation-id)))

(define-read-only (get-incident (incident-id uint))
  (ok (map-get? incident-reports incident-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-incident-id (incident-id uint))
  (ok (int-to-ascii incident-id)))

(define-read-only (parse-incident-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
