;; access-audit - Clarity 4
;; Comprehensive audit trail for genomic data access

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-AUDIT-NOT-FOUND (err u101))
(define-constant ERR-INVALID-ACTION (err u102))
(define-constant ERR-RESOURCE-NOT-FOUND (err u103))

(define-constant ACTION-READ "read")
(define-constant ACTION-WRITE "write")
(define-constant ACTION-DELETE "delete")
(define-constant ACTION-SHARE "share")
(define-constant ACTION-EXPORT "export")

(define-map audit-logs uint
  {
    resource-id: uint,
    resource-type: (string-ascii 50),
    accessor: principal,
    action: (string-ascii 20),
    timestamp: uint,
    success: bool,
    ip-hash: (buff 32),
    metadata: (string-utf8 200)
  }
)

(define-map access-stats { resource-id: uint, accessor: principal }
  {
    total-accesses: uint,
    last-access: uint,
    failed-attempts: uint
  }
)

(define-map resource-owners uint
  {
    owner: principal,
    created-at: uint,
    audit-enabled: bool
  }
)

(define-map suspicious-activity principal
  {
    failed-login-attempts: uint,
    last-failed-attempt: uint,
    is-blocked: bool,
    blocked-until: uint
  }
)

(define-data-var audit-counter uint u0)
(define-data-var max-failed-attempts uint u5)
(define-data-var block-duration uint u86400) ;; 24 hours

;; Log access attempt
(define-public (log-access
    (resource-id uint)
    (resource-type (string-ascii 50))
    (action (string-ascii 20))
    (success bool)
    (ip-hash (buff 32))
    (metadata (string-utf8 200)))
  (let ((audit-id (+ (var-get audit-counter) u1)))
    (map-set audit-logs audit-id
      {
        resource-id: resource-id,
        resource-type: resource-type,
        accessor: tx-sender,
        action: action,
        timestamp: stacks-block-time,
        success: success,
        ip-hash: ip-hash,
        metadata: metadata
      })
    (update-access-stats resource-id tx-sender success)
    (if (not success)
      (track-failed-attempt tx-sender)
      true)
    (var-set audit-counter audit-id)
    (ok audit-id)))

;; Register resource for auditing
(define-public (register-resource (resource-id uint))
  (begin
    (asserts! (is-none (map-get? resource-owners resource-id)) (err u104))
    (ok (map-set resource-owners resource-id
      {
        owner: tx-sender,
        created-at: stacks-block-time,
        audit-enabled: true
      }))))

;; Enable/disable auditing
(define-public (toggle-auditing (resource-id uint) (enabled bool))
  (let ((resource (unwrap! (map-get? resource-owners resource-id) ERR-RESOURCE-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner resource)) ERR-NOT-AUTHORIZED)
    (ok (map-set resource-owners resource-id (merge resource { audit-enabled: enabled })))))

;; Update access statistics
(define-private (update-access-stats (resource-id uint) (accessor principal) (success bool))
  (let ((stats (default-to
                 { total-accesses: u0, last-access: u0, failed-attempts: u0 }
                 (map-get? access-stats { resource-id: resource-id, accessor: accessor }))))
    (map-set access-stats { resource-id: resource-id, accessor: accessor }
      {
        total-accesses: (+ (get total-accesses stats) u1),
        last-access: stacks-block-time,
        failed-attempts: (if success
                           (get failed-attempts stats)
                           (+ (get failed-attempts stats) u1))
      })
    true))

;; Track failed login attempts
(define-private (track-failed-attempt (accessor principal))
  (let ((activity (default-to
                    { failed-login-attempts: u0, last-failed-attempt: u0, is-blocked: false, blocked-until: u0 }
                    (map-get? suspicious-activity accessor))))
    (let ((new-attempts (+ (get failed-login-attempts activity) u1)))
      (map-set suspicious-activity accessor
        {
          failed-login-attempts: new-attempts,
          last-failed-attempt: stacks-block-time,
          is-blocked: (>= new-attempts (var-get max-failed-attempts)),
          blocked-until: (if (>= new-attempts (var-get max-failed-attempts))
                           (+ stacks-block-time (var-get block-duration))
                           (get blocked-until activity))
        })
      true)))

;; Clear failed attempts after successful login
(define-public (clear-failed-attempts (accessor principal))
  (ok (map-delete suspicious-activity accessor)))

;; Read-only functions
(define-read-only (get-audit-log (audit-id uint))
  (ok (map-get? audit-logs audit-id)))

(define-read-only (get-access-stats (resource-id uint) (accessor principal))
  (ok (map-get? access-stats { resource-id: resource-id, accessor: accessor })))

(define-read-only (get-resource-info (resource-id uint))
  (ok (map-get? resource-owners resource-id)))

(define-read-only (get-suspicious-activity (accessor principal))
  (ok (map-get? suspicious-activity accessor)))

(define-read-only (is-accessor-blocked (accessor principal))
  (let ((activity (map-get? suspicious-activity accessor)))
    (ok (match activity
          record (and (get is-blocked record) (< stacks-block-time (get blocked-until record)))
          false))))

(define-read-only (get-total-audit-logs)
  (ok (var-get audit-counter)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-accessor (accessor principal))
  (principal-destruct? accessor))

;; Clarity 4: int-to-ascii
(define-read-only (format-audit-id (audit-id uint))
  (ok (int-to-ascii audit-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-audit-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
