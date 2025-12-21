;; key-management - Clarity 4
;; Cryptographic key lifecycle management

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-KEY-NOT-FOUND (err u101))
(define-constant ERR-KEY-EXPIRED (err u102))
(define-constant ERR-KEY-REVOKED (err u103))
(define-constant ERR-INVALID-KEY (err u104))

(define-map encryption-keys (buff 64)
  {
    owner: principal,
    key-type: (string-ascii 20),
    algorithm: (string-ascii 50),
    created-at: uint,
    expires-at: uint,
    is-active: bool,
    rotation-count: uint
  }
)

(define-map key-permissions { key-hash: (buff 64), grantee: principal }
  {
    permission-level: (string-ascii 20),
    granted-at: uint,
    expires-at: uint
  }
)

(define-map key-rotation-history uint
  {
    old-key-hash: (buff 64),
    new-key-hash: (buff 64),
    rotated-by: principal,
    rotated-at: uint,
    reason: (string-utf8 200)
  }
)

(define-map key-escrow (buff 64)
  {
    escrow-holder: principal,
    recovery-threshold: uint,
    shard-count: uint,
    created-at: uint
  }
)

(define-data-var rotation-counter uint u0)
(define-data-var default-key-lifetime uint u31536000) ;; 1 year

;; Register encryption key
(define-public (register-key
    (key-hash (buff 64))
    (key-type (string-ascii 20))
    (algorithm (string-ascii 50))
    (lifetime uint))
  (begin
    (asserts! (is-none (map-get? encryption-keys key-hash)) ERR-INVALID-KEY)
    (ok (map-set encryption-keys key-hash
      {
        owner: tx-sender,
        key-type: key-type,
        algorithm: algorithm,
        created-at: stacks-block-time,
        expires-at: (+ stacks-block-time lifetime),
        is-active: true,
        rotation-count: u0
      }))))

;; Rotate key
(define-public (rotate-key
    (old-key-hash (buff 64))
    (new-key-hash (buff 64))
    (reason (string-utf8 200)))
  (let ((old-key (unwrap! (map-get? encryption-keys old-key-hash) ERR-KEY-NOT-FOUND))
        (rotation-id (+ (var-get rotation-counter) u1)))
    (asserts! (is-eq tx-sender (get owner old-key)) ERR-NOT-AUTHORIZED)
    (map-set encryption-keys old-key-hash (merge old-key { is-active: false }))
    (map-set encryption-keys new-key-hash
      {
        owner: tx-sender,
        key-type: (get key-type old-key),
        algorithm: (get algorithm old-key),
        created-at: stacks-block-time,
        expires-at: (+ stacks-block-time (var-get default-key-lifetime)),
        is-active: true,
        rotation-count: (+ (get rotation-count old-key) u1)
      })
    (map-set key-rotation-history rotation-id
      {
        old-key-hash: old-key-hash,
        new-key-hash: new-key-hash,
        rotated-by: tx-sender,
        rotated-at: stacks-block-time,
        reason: reason
      })
    (var-set rotation-counter rotation-id)
    (ok rotation-id)))

;; Grant key permission
(define-public (grant-key-permission
    (key-hash (buff 64))
    (grantee principal)
    (permission-level (string-ascii 20))
    (duration uint))
  (let ((key (unwrap! (map-get? encryption-keys key-hash) ERR-KEY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner key)) ERR-NOT-AUTHORIZED)
    (ok (map-set key-permissions { key-hash: key-hash, grantee: grantee }
      {
        permission-level: permission-level,
        granted-at: stacks-block-time,
        expires-at: (+ stacks-block-time duration)
      }))))

;; Revoke key
(define-public (revoke-key (key-hash (buff 64)))
  (let ((key (unwrap! (map-get? encryption-keys key-hash) ERR-KEY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner key)) ERR-NOT-AUTHORIZED)
    (ok (map-set encryption-keys key-hash (merge key { is-active: false })))))

;; Setup key escrow
(define-public (setup-escrow
    (key-hash (buff 64))
    (escrow-holder principal)
    (recovery-threshold uint)
    (shard-count uint))
  (let ((key (unwrap! (map-get? encryption-keys key-hash) ERR-KEY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner key)) ERR-NOT-AUTHORIZED)
    (ok (map-set key-escrow key-hash
      {
        escrow-holder: escrow-holder,
        recovery-threshold: recovery-threshold,
        shard-count: shard-count,
        created-at: stacks-block-time
      }))))

;; Read-only functions
(define-read-only (get-key-info (key-hash (buff 64)))
  (ok (map-get? encryption-keys key-hash)))

(define-read-only (get-key-permission (key-hash (buff 64)) (grantee principal))
  (ok (map-get? key-permissions { key-hash: key-hash, grantee: grantee })))

(define-read-only (get-rotation-history (rotation-id uint))
  (ok (map-get? key-rotation-history rotation-id)))

(define-read-only (get-escrow-info (key-hash (buff 64)))
  (ok (map-get? key-escrow key-hash)))

(define-read-only (is-key-valid (key-hash (buff 64)))
  (match (map-get? encryption-keys key-hash)
    key (ok (and (get is-active key) (< stacks-block-time (get expires-at key))))
    (ok false)))

(define-read-only (get-total-rotations)
  (ok (var-get rotation-counter)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-owner (owner principal))
  (principal-destruct? owner))

;; Clarity 4: int-to-ascii
(define-read-only (format-rotation-id (rotation-id uint))
  (ok (int-to-ascii rotation-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-rotation-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
