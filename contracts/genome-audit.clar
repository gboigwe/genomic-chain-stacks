;; genome-audit.clar - Clarity 4
;; Audit trail for genomic data access and modifications

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-AUDIT-NOT-FOUND (err u101))

(define-data-var audit-counter uint u0)

(define-map audit-log
  { audit-id: uint }
  {
    resource-id: uint,
    actor: principal,
    action: (string-ascii 50),
    timestamp: uint,
    ip-hash: (optional (buff 32)),
    success: bool,
    details: (string-utf8 256)
  }
)

(define-public (log-access
    (resource-id uint)
    (action (string-ascii 50))
    (ip-hash (optional (buff 32)))
    (success bool)
    (details (string-utf8 256)))
  (let
    ((new-audit-id (+ (var-get audit-counter) u1)))
    (map-set audit-log { audit-id: new-audit-id }
      {
        resource-id: resource-id,
        actor: tx-sender,
        action: action,
        timestamp: stacks-block-time,
        ip-hash: ip-hash,
        success: success,
        details: details
      })
    (var-set audit-counter new-audit-id)
    (ok new-audit-id)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-actor (actor principal))
  (principal-destruct? actor))

;; Clarity 4: int-to-utf8
(define-read-only (format-audit-id (audit-id uint))
  (ok (int-to-utf8 audit-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-audit-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: buff-to-uint-le
(define-read-only (ip-hash-to-number (ip-buff (buff 16)))
  (ok (buff-to-uint-le ip-buff)))

(define-read-only (get-audit-entry (audit-id uint))
  (ok (map-get? audit-log { audit-id: audit-id })))

(define-read-only (get-audit-counter)
  (ok (var-get audit-counter)))
