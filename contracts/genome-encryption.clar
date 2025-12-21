;; genome-encryption - Clarity 4
;; Comprehensive encryption key management for genomic data

(define-constant ERR-KEY-NOT-FOUND (err u100))
(define-constant ERR-NOT-OWNER (err u101))
(define-constant ERR-KEY-EXPIRED (err u102))
(define-constant ERR-ALREADY-REVOKED (err u103))

(define-map encryption-keys uint
  {
    owner: principal,
    key-hash: (buff 64),
    algorithm: (string-ascii 20),
    key-version: uint,
    created-at: uint,
    expires-at: uint,
    is-revoked: bool
  }
)

(define-map key-access-grants { key-id: uint, grantee: principal }
  {
    access-level: (string-ascii 20),
    granted-at: uint,
    granted-by: principal,
    expires-at: uint,
    is-active: bool
  }
)

(define-map key-rotation-history uint
  {
    old-key-id: uint,
    new-key-id: uint,
    rotated-by: principal,
    rotated-at: uint,
    rotation-reason: (string-utf8 200)
  }
)

(define-map key-usage-logs uint
  {
    key-id: uint,
    used-by: principal,
    operation-type: (string-ascii 50),
    used-at: uint,
    success: bool
  }
)

(define-data-var key-counter uint u0)
(define-data-var rotation-counter uint u0)
(define-data-var usage-log-counter uint u0)
(define-data-var default-key-lifetime uint u5256000) ;; ~100 years in blocks

(define-public (register-key
    (key-hash (buff 64))
    (algorithm (string-ascii 20))
    (lifetime uint))
  (let ((key-id (+ (var-get key-counter) u1)))
    (map-set encryption-keys key-id
      {
        owner: tx-sender,
        key-hash: key-hash,
        algorithm: algorithm,
        key-version: u1,
        created-at: stacks-block-time,
        expires-at: (+ stacks-block-time lifetime),
        is-revoked: false
      })
    (var-set key-counter key-id)
    (ok key-id)))

(define-public (rotate-key
    (old-key-id uint)
    (new-key-hash (buff 64))
    (rotation-reason (string-utf8 200)))
  (let ((old-key (unwrap! (map-get? encryption-keys old-key-id) ERR-KEY-NOT-FOUND))
        (new-key-id (+ (var-get key-counter) u1))
        (rotation-id (+ (var-get rotation-counter) u1)))
    (asserts! (is-eq tx-sender (get owner old-key)) ERR-NOT-OWNER)
    (map-set encryption-keys new-key-id
      {
        owner: tx-sender,
        key-hash: new-key-hash,
        algorithm: (get algorithm old-key),
        key-version: (+ (get key-version old-key) u1),
        created-at: stacks-block-time,
        expires-at: (+ stacks-block-time (var-get default-key-lifetime)),
        is-revoked: false
      })
    (map-set key-rotation-history rotation-id
      {
        old-key-id: old-key-id,
        new-key-id: new-key-id,
        rotated-by: tx-sender,
        rotated-at: stacks-block-time,
        rotation-reason: rotation-reason
      })
    (var-set key-counter new-key-id)
    (var-set rotation-counter rotation-id)
    (ok new-key-id)))

(define-public (grant-key-access
    (key-id uint)
    (grantee principal)
    (access-level (string-ascii 20))
    (duration uint))
  (let ((key (unwrap! (map-get? encryption-keys key-id) ERR-KEY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner key)) ERR-NOT-OWNER)
    (asserts! (not (get is-revoked key)) ERR-ALREADY-REVOKED)
    (ok (map-set key-access-grants { key-id: key-id, grantee: grantee }
      {
        access-level: access-level,
        granted-at: stacks-block-time,
        granted-by: tx-sender,
        expires-at: (+ stacks-block-time duration),
        is-active: true
      }))))

(define-public (revoke-key-access
    (key-id uint)
    (grantee principal))
  (let ((key (unwrap! (map-get? encryption-keys key-id) ERR-KEY-NOT-FOUND))
        (grant (unwrap! (map-get? key-access-grants { key-id: key-id, grantee: grantee }) ERR-KEY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner key)) ERR-NOT-OWNER)
    (ok (map-set key-access-grants { key-id: key-id, grantee: grantee }
      (merge grant { is-active: false })))))

(define-public (revoke-key (key-id uint))
  (let ((key (unwrap! (map-get? encryption-keys key-id) ERR-KEY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner key)) ERR-NOT-OWNER)
    (asserts! (not (get is-revoked key)) ERR-ALREADY-REVOKED)
    (ok (map-set encryption-keys key-id
      (merge key { is-revoked: true })))))

(define-public (log-key-usage
    (key-id uint)
    (operation-type (string-ascii 50))
    (success bool))
  (let ((log-id (+ (var-get usage-log-counter) u1))
        (key (unwrap! (map-get? encryption-keys key-id) ERR-KEY-NOT-FOUND)))
    (map-set key-usage-logs log-id
      {
        key-id: key-id,
        used-by: tx-sender,
        operation-type: operation-type,
        used-at: stacks-block-time,
        success: success
      })
    (var-set usage-log-counter log-id)
    (ok log-id)))

(define-read-only (get-key-info (key-id uint))
  (ok (map-get? encryption-keys key-id)))

(define-read-only (get-key-access (key-id uint) (grantee principal))
  (ok (map-get? key-access-grants { key-id: key-id, grantee: grantee })))

(define-read-only (get-rotation-history (rotation-id uint))
  (ok (map-get? key-rotation-history rotation-id)))

(define-read-only (get-usage-log (log-id uint))
  (ok (map-get? key-usage-logs log-id)))

(define-read-only (is-key-valid (key-id uint))
  (match (map-get? encryption-keys key-id)
    key (ok (and
      (not (get is-revoked key))
      (< stacks-block-time (get expires-at key))))
    ERR-KEY-NOT-FOUND))

(define-read-only (validate-owner (owner principal))
  (principal-destruct? owner))

(define-read-only (format-key-id (key-id uint))
  (ok (int-to-ascii key-id)))

(define-read-only (parse-key-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
