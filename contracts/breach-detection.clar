;; breach-detection - Clarity 4
;; Automated security breach detection and alerting

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALERT-NOT-FOUND (err u101))
(define-constant ERR-INVALID-SEVERITY (err u102))

(define-map security-alerts uint
  {
    alert-type: (string-ascii 50),
    severity: (string-ascii 20),
    affected-resource: uint,
    detected-by: principal,
    detection-timestamp: uint,
    threat-indicators: (buff 128),
    is-confirmed: bool,
    resolution-status: (string-ascii 20)
  }
)

(define-map threat-patterns (buff 64)
  {
    pattern-name: (string-ascii 100),
    risk-score: uint,
    created-at: uint,
    detection-count: uint
  }
)

(define-map security-incidents uint
  {
    incident-type: (string-ascii 50),
    severity-level: uint,
    affected-systems: (list 10 uint),
    reported-at: uint,
    investigator: (optional principal),
    status: (string-ascii 20)
  }
)

(define-map anomaly-scores principal
  {
    total-anomalies: uint,
    last-anomaly: uint,
    risk-level: (string-ascii 20)
  }
)

(define-data-var alert-counter uint u0)
(define-data-var incident-counter uint u0)
(define-data-var alert-threshold uint u5)

(define-public (raise-security-alert
    (alert-type (string-ascii 50))
    (severity (string-ascii 20))
    (affected-resource uint)
    (threat-indicators (buff 128)))
  (let ((alert-id (+ (var-get alert-counter) u1)))
    (map-set security-alerts alert-id
      {
        alert-type: alert-type,
        severity: severity,
        affected-resource: affected-resource,
        detected-by: tx-sender,
        detection-timestamp: stacks-block-time,
        threat-indicators: threat-indicators,
        is-confirmed: false,
        resolution-status: "open"
      })
    (update-anomaly-score tx-sender)
    (var-set alert-counter alert-id)
    (ok alert-id)))

(define-public (confirm-alert (alert-id uint))
  (let ((alert (unwrap! (map-get? security-alerts alert-id) ERR-ALERT-NOT-FOUND)))
    (ok (map-set security-alerts alert-id
      (merge alert { is-confirmed: true })))))

(define-public (create-incident
    (incident-type (string-ascii 50))
    (severity-level uint)
    (affected-systems (list 10 uint)))
  (let ((incident-id (+ (var-get incident-counter) u1)))
    (asserts! (<= severity-level u5) ERR-INVALID-SEVERITY)
    (map-set security-incidents incident-id
      {
        incident-type: incident-type,
        severity-level: severity-level,
        affected-systems: affected-systems,
        reported-at: stacks-block-time,
        investigator: none,
        status: "investigating"
      })
    (var-set incident-counter incident-id)
    (ok incident-id)))

(define-public (assign-investigator (incident-id uint) (investigator principal))
  (let ((incident (unwrap! (map-get? security-incidents incident-id) ERR-ALERT-NOT-FOUND)))
    (ok (map-set security-incidents incident-id
      (merge incident { investigator: (some investigator) })))))

(define-public (register-threat-pattern
    (pattern-hash (buff 64))
    (pattern-name (string-ascii 100))
    (risk-score uint))
  (ok (map-set threat-patterns pattern-hash
    {
      pattern-name: pattern-name,
      risk-score: risk-score,
      created-at: stacks-block-time,
      detection-count: u0
    })))

(define-private (update-anomaly-score (user principal))
  (let ((score (default-to
                 { total-anomalies: u0, last-anomaly: u0, risk-level: "low" }
                 (map-get? anomaly-scores user))))
    (let ((new-total (+ (get total-anomalies score) u1)))
      (map-set anomaly-scores user
        {
          total-anomalies: new-total,
          last-anomaly: stacks-block-time,
          risk-level: (if (>= new-total (var-get alert-threshold)) "high" "low")
        })
      true)))

(define-read-only (get-alert (alert-id uint))
  (ok (map-get? security-alerts alert-id)))

(define-read-only (get-incident (incident-id uint))
  (ok (map-get? security-incidents incident-id)))

(define-read-only (get-threat-pattern (pattern-hash (buff 64)))
  (ok (map-get? threat-patterns pattern-hash)))

(define-read-only (get-anomaly-score (user principal))
  (ok (map-get? anomaly-scores user)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-alert-id (alert-id uint))
  (ok (int-to-ascii alert-id)))

(define-read-only (parse-alert-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
