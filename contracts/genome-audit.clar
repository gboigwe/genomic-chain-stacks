;; genome-audit - Clarity 4
;; Immutable audit trail for genomic data access

(define-constant ERR-LOG-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-ACTION (err u102))

(define-map audit-logs uint
  {
    resource-id: uint,
    accessor: principal,
    action: (string-ascii 50),
    timestamp: uint,
    result: (string-ascii 20),
    ip-hash: (optional (buff 32)),
    session-id: (string-ascii 64),
    details: (string-utf8 500)
  }
)

(define-map access-patterns uint
  {
    resource-id: uint,
    accessor: principal,
    access-count: uint,
    first-access: uint,
    last-access: uint,
    failed-attempts: uint
  }
)

(define-map compliance-logs uint
  {
    audit-log-id: uint,
    compliance-standard: (string-ascii 50),
    compliant: bool,
    checked-at: uint,
    checked-by: principal,
    violations: (optional (string-utf8 500))
  }
)

(define-map audit-alerts uint
  {
    resource-id: uint,
    alert-type: (string-ascii 50),
    severity: (string-ascii 20),
    triggered-at: uint,
    triggered-by: principal,
    resolved: bool,
    resolution-notes: (optional (string-utf8 300))
  }
)

(define-map retention-policies uint
  {
    resource-type: (string-ascii 50),
    retention-period: uint,
    archive-after: uint,
    delete-after: (optional uint),
    policy-owner: principal
  }
)

(define-map audit-reports uint
  {
    report-period-start: uint,
    report-period-end: uint,
    total-accesses: uint,
    unique-accessors: uint,
    failed-accesses: uint,
    generated-at: uint,
    generated-by: principal
  }
)

(define-data-var log-counter uint u0)
(define-data-var pattern-counter uint u0)
(define-data-var compliance-counter uint u0)
(define-data-var alert-counter uint u0)
(define-data-var policy-counter uint u0)
(define-data-var report-counter uint u0)

(define-public (log-access
    (resource-id uint)
    (action (string-ascii 50))
    (result (string-ascii 20))
    (ip-hash (optional (buff 32)))
    (session-id (string-ascii 64))
    (details (string-utf8 500)))
  (let ((log-id (+ (var-get log-counter) u1)))
    (map-set audit-logs log-id
      {
        resource-id: resource-id,
        accessor: tx-sender,
        action: action,
        timestamp: stacks-block-time,
        result: result,
        ip-hash: ip-hash,
        session-id: session-id,
        details: details
      })
    (unwrap-panic (update-access-pattern resource-id tx-sender (is-eq result "success")))
    (var-set log-counter log-id)
    (ok log-id)))

(define-private (update-access-pattern (resource-id uint) (accessor principal) (success bool))
  (let ((pattern-id (+ (var-get pattern-counter) u1))
        (existing (map-get? access-patterns pattern-id)))
    (match existing
      pattern
        (map-set access-patterns pattern-id
          (merge pattern {
            access-count: (+ (get access-count pattern) u1),
            last-access: stacks-block-time,
            failed-attempts: (if success (get failed-attempts pattern) (+ (get failed-attempts pattern) u1))
          }))
        (map-set access-patterns pattern-id
          {
            resource-id: resource-id,
            accessor: accessor,
            access-count: u1,
            first-access: stacks-block-time,
            last-access: stacks-block-time,
            failed-attempts: (if success u0 u1)
          }))
    (var-set pattern-counter pattern-id)
    (ok true)))

(define-public (log-compliance-check
    (audit-log-id uint)
    (compliance-standard (string-ascii 50))
    (compliant bool)
    (violations (optional (string-utf8 500))))
  (let ((compliance-id (+ (var-get compliance-counter) u1)))
    (asserts! (is-some (map-get? audit-logs audit-log-id)) ERR-LOG-NOT-FOUND)
    (map-set compliance-logs compliance-id
      {
        audit-log-id: audit-log-id,
        compliance-standard: compliance-standard,
        compliant: compliant,
        checked-at: stacks-block-time,
        checked-by: tx-sender,
        violations: violations
      })
    (var-set compliance-counter compliance-id)
    (ok compliance-id)))

(define-public (create-audit-alert
    (resource-id uint)
    (alert-type (string-ascii 50))
    (severity (string-ascii 20)))
  (let ((alert-id (+ (var-get alert-counter) u1)))
    (map-set audit-alerts alert-id
      {
        resource-id: resource-id,
        alert-type: alert-type,
        severity: severity,
        triggered-at: stacks-block-time,
        triggered-by: tx-sender,
        resolved: false,
        resolution-notes: none
      })
    (var-set alert-counter alert-id)
    (ok alert-id)))

(define-public (resolve-audit-alert
    (alert-id uint)
    (resolution-notes (string-utf8 300)))
  (let ((alert (unwrap! (map-get? audit-alerts alert-id) ERR-LOG-NOT-FOUND)))
    (ok (map-set audit-alerts alert-id
      (merge alert {
        resolved: true,
        resolution-notes: (some resolution-notes)
      })))))

(define-public (create-retention-policy
    (resource-type (string-ascii 50))
    (retention-period uint)
    (archive-after uint)
    (delete-after (optional uint)))
  (let ((policy-id (+ (var-get policy-counter) u1)))
    (map-set retention-policies policy-id
      {
        resource-type: resource-type,
        retention-period: retention-period,
        archive-after: archive-after,
        delete-after: delete-after,
        policy-owner: tx-sender
      })
    (var-set policy-counter policy-id)
    (ok policy-id)))

(define-public (generate-audit-report
    (period-start uint)
    (period-end uint)
    (total-accesses uint)
    (unique-accessors uint)
    (failed-accesses uint))
  (let ((report-id (+ (var-get report-counter) u1)))
    (map-set audit-reports report-id
      {
        report-period-start: period-start,
        report-period-end: period-end,
        total-accesses: total-accesses,
        unique-accessors: unique-accessors,
        failed-accesses: failed-accesses,
        generated-at: stacks-block-time,
        generated-by: tx-sender
      })
    (var-set report-counter report-id)
    (ok report-id)))

(define-read-only (get-log (log-id uint))
  (ok (map-get? audit-logs log-id)))

(define-read-only (get-access-pattern (pattern-id uint))
  (ok (map-get? access-patterns pattern-id)))

(define-read-only (get-compliance-log (compliance-id uint))
  (ok (map-get? compliance-logs compliance-id)))

(define-read-only (get-audit-alert (alert-id uint))
  (ok (map-get? audit-alerts alert-id)))

(define-read-only (get-retention-policy (policy-id uint))
  (ok (map-get? retention-policies policy-id)))

(define-read-only (get-audit-report (report-id uint))
  (ok (map-get? audit-reports report-id)))

(define-read-only (validate-accessor (accessor principal))
  (principal-destruct? accessor))

(define-read-only (format-log-id (log-id uint))
  (ok (int-to-ascii log-id)))

(define-read-only (parse-log-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
