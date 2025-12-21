;; genome-access-control.clar - Clarity 4
;; Access permissions for genomic data

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PERMISSION-NOT-FOUND (err u101))
(define-constant ERR-INVALID-LEVEL (err u102))

(define-map access-permissions
  { resource-id: uint, user: principal }
  {
    access-level: uint,
    granted-by: principal,
    granted-at: uint,
    expires-at: uint,
    can-share: bool,
    can-modify: bool
  }
)

(define-map resource-owners
  { resource-id: uint }
  { owner: principal, created-at: uint }
)

(define-public (grant-permission
    (resource-id uint)
    (user principal)
    (access-level uint)
    (expiration uint)
    (can-share bool)
    (can-modify bool))
  (let
    ((owner-data (unwrap! (map-get? resource-owners { resource-id: resource-id }) ERR-NOT-AUTHORIZED)))
    (asserts! (is-eq tx-sender (get owner owner-data)) ERR-NOT-AUTHORIZED)
    (asserts! (<= access-level u3) ERR-INVALID-LEVEL)
    (map-set access-permissions { resource-id: resource-id, user: user }
      {
        access-level: access-level,
        granted-by: tx-sender,
        granted-at: stacks-block-time,
        expires-at: expiration,
        can-share: can-share,
        can-modify: can-modify
      })
    (ok true)))

(define-public (revoke-permission (resource-id uint) (user principal))
  (let
    ((owner-data (unwrap! (map-get? resource-owners { resource-id: resource-id }) ERR-NOT-AUTHORIZED)))
    (asserts! (is-eq tx-sender (get owner owner-data)) ERR-NOT-AUTHORIZED)
    (ok (map-delete access-permissions { resource-id: resource-id, user: user }))))

(define-public (register-resource (resource-id uint))
  (begin
    (map-set resource-owners { resource-id: resource-id }
      { owner: tx-sender, created-at: stacks-block-time })
    (ok true)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-user (user principal))
  (principal-destruct? user))

;; Clarity 4: int-to-ascii
(define-read-only (format-resource-id (resource-id uint))
  (ok (int-to-ascii resource-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-resource-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block)
  (ok burn-block-height))

(define-read-only (get-permission (resource-id uint) (user principal))
  (ok (map-get? access-permissions { resource-id: resource-id, user: user })))

(define-read-only (has-access (resource-id uint) (user principal))
  (match (map-get? access-permissions { resource-id: resource-id, user: user })
    permission (ok (< stacks-block-time (get expires-at permission)))
    (ok false)))
