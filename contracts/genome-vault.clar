;; genome-vault - Clarity 4
;; Encrypted genomic storage with access control

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-VAULT-EXISTS (err u101))
(define-constant ERR-VAULT-NOT-FOUND (err u102))

(define-data-var vault-counter uint u0)

(define-map vaults
  { vault-id: uint }
  {
    owner: principal,
    encrypted-data-hash: (buff 64),
    storage-url: (string-utf8 256),
    created-at: uint,
    updated-at: uint,
    is-active: bool
  }
)

(define-map vault-keys
  { vault-id: uint, authorized-principal: principal }
  {
    encrypted-key: (buff 128),
    granted-at: uint,
    expires-at: uint
  }
)

(define-public (create-vault
    (encrypted-hash (buff 64))
    (storage-url (string-utf8 256)))
  (let
    ((new-vault-id (+ (var-get vault-counter) u1)))
    (asserts! (is-none (map-get? vaults { vault-id: new-vault-id })) ERR-VAULT-EXISTS)
    (map-set vaults { vault-id: new-vault-id }
      {
        owner: tx-sender,
        encrypted-data-hash: encrypted-hash,
        storage-url: storage-url,
        created-at: stacks-block-time,
        updated-at: stacks-block-time,
        is-active: true
      })
    (var-set vault-counter new-vault-id)
    (ok new-vault-id)))

(define-public (grant-access
    (vault-id uint)
    (authorized-user principal)
    (encrypted-key (buff 128))
    (expiration uint))
  (let
    ((vault (unwrap! (map-get? vaults { vault-id: vault-id }) ERR-VAULT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner vault)) ERR-NOT-AUTHORIZED)
    (map-set vault-keys { vault-id: vault-id, authorized-principal: authorized-user }
      {
        encrypted-key: encrypted-key,
        granted-at: stacks-block-time,
        expires-at: expiration
      })
    (ok true)))

;; Clarity 4: principal-destruct? - Validate vault owner
(define-read-only (validate-owner (owner principal))
  (principal-destruct? owner))

;; Clarity 4: int-to-ascii - Format vault ID
(define-read-only (format-vault-id (vault-id uint))
  (ok (int-to-ascii vault-id)))

;; Clarity 4: string-to-uint? - Parse vault ID
(define-read-only (parse-vault-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height - Bitcoin block height
(define-read-only (get-bitcoin-height)
  (ok burn-block-height))

(define-read-only (get-vault (vault-id uint))
  (ok (map-get? vaults { vault-id: vault-id })))

(define-read-only (get-access-key (vault-id uint) (user principal))
  (ok (map-get? vault-keys { vault-id: vault-id, authorized-principal: user })))
