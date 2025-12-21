;; genome-encryption.clar - Clarity 4
;; Key management for genomic data encryption

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-KEY-NOT-FOUND (err u101))
(define-constant ERR-KEY-EXPIRED (err u102))

(define-data-var key-counter uint u0)

(define-map encryption-keys
  { key-id: uint }
  {
    owner: principal,
    encrypted-key: (buff 256),
    algorithm: (string-ascii 30),
    created-at: uint,
    expires-at: uint,
    is-active: bool
  }
)

(define-public (create-key
    (encrypted-key (buff 256))
    (algorithm (string-ascii 30))
    (expiration uint))
  (let
    ((new-key-id (+ (var-get key-counter) u1)))
    (map-set encryption-keys { key-id: new-key-id }
      {
        owner: tx-sender,
        encrypted-key: encrypted-key,
        algorithm: algorithm,
        created-at: stacks-block-time,
        expires-at: expiration,
        is-active: true
      })
    (var-set key-counter new-key-id)
    (ok new-key-id)))

(define-public (rotate-key
    (key-id uint)
    (new-encrypted-key (buff 256)))
  (let
    ((key (unwrap! (map-get? encryption-keys { key-id: key-id }) ERR-KEY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner key)) ERR-NOT-AUTHORIZED)
    (map-set encryption-keys { key-id: key-id }
      (merge key { encrypted-key: new-encrypted-key }))
    (ok true)))

;; Clarity 4: principal-destruct? - Validate owner
(define-read-only (validate-owner (owner principal))
  (principal-destruct? owner))

;; Clarity 4: int-to-ascii - Format key ID
(define-read-only (format-key-id (key-id uint))
  (ok (int-to-ascii key-id)))

;; Clarity 4: string-to-uint? - Parse key ID
(define-read-only (parse-key-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: stacks-block-time - Current timestamp
(define-read-only (get-block-time)
  (ok stacks-block-time))

(define-read-only (get-key (key-id uint))
  (ok (map-get? encryption-keys { key-id: key-id })))

(define-read-only (is-key-valid (key-id uint))
  (match (map-get? encryption-keys { key-id: key-id })
    key (ok (and (get is-active key) (< stacks-block-time (get expires-at key))))
    (ok false)))
