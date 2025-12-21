;; genome-vault.clar - Clarity 4
;; Encrypted genomic storage with access control

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-VAULT-EXISTS (err u101))
(define-constant ERR-VAULT-NOT-FOUND (err u102))
(define-constant ERR-INVALID-KEY (err u103))

;; Data Variables
(define-data-var vault-counter uint u0)
(define-data-var contract-owner principal tx-sender)

;; Genomic vault storage
(define-map vaults
  { vault-id: uint }
  {
    owner: principal,
    encrypted-data-hash: (buff 64),
    storage-url: (string-utf8 256),
    encryption-method: (string-ascii 20),
    created-at: uint,
    updated-at: uint,
    access-count: uint,
    is-active: bool
  }
)

;; Access keys for encrypted data
(define-map vault-keys
  { vault-id: uint, authorized-principal: principal }
  {
    encrypted-key: (buff 128),
    granted-at: uint,
    expires-at: uint,
    access-level: uint
  }
)

;; Create new genomic vault
(define-public (create-vault
    (encrypted-hash (buff 64))
    (storage-url (string-utf8 256))
    (encryption-method (string-ascii 20)))
  (let
    ((new-vault-id (+ (var-get vault-counter) u1)))
    (asserts! (is-none (map-get? vaults { vault-id: new-vault-id })) ERR-VAULT-EXISTS)
    (map-set vaults { vault-id: new-vault-id }
      {
        owner: tx-sender,
        encrypted-data-hash: encrypted-hash,
        storage-url: storage-url,
        encryption-method: encryption-method,
        created-at: stacks-block-time,
        updated-at: stacks-block-time,
        access-count: u0,
        is-active: true
      })
    (var-set vault-counter new-vault-id)
    (ok new-vault-id)))

;; Grant access to vault
(define-public (grant-access
    (vault-id uint)
    (authorized-user principal)
    (encrypted-key (buff 128))
    (expiration uint)
    (access-level uint))
  (let
    ((vault (unwrap! (map-get? vaults { vault-id: vault-id }) ERR-VAULT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner vault)) ERR-NOT-AUTHORIZED)
    (map-set vault-keys { vault-id: vault-id, authorized-principal: authorized-user }
      {
        encrypted-key: encrypted-key,
        granted-at: stacks-block-time,
        expires-at: expiration,
        access-level: access-level
      })
    (ok true)))

;; Revoke access
(define-public (revoke-access (vault-id uint) (user principal))
  (let
    ((vault (unwrap! (map-get? vaults { vault-id: vault-id }) ERR-VAULT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner vault)) ERR-NOT-AUTHORIZED)
    (ok (map-delete vault-keys { vault-id: vault-id, authorized-principal: user }))))

;; Update vault data
(define-public (update-vault
    (vault-id uint)
    (new-hash (buff 64))
    (new-url (string-utf8 256)))
  (let
    ((vault (unwrap! (map-get? vaults { vault-id: vault-id }) ERR-VAULT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner vault)) ERR-NOT-AUTHORIZED)
    (map-set vaults { vault-id: vault-id }
      (merge vault {
        encrypted-data-hash: new-hash,
        storage-url: new-url,
        updated-at: stacks-block-time
      }))
    (ok true)))

;; Clarity 4: principal-destruct? - Validate vault owner
(define-read-only (validate-vault-owner (owner principal))
  (principal-destruct? owner))

;; Clarity 4: int-to-ascii - Format vault ID
(define-read-only (format-vault-id (vault-id uint))
  (ok (int-to-ascii vault-id)))

;; Clarity 4: string-to-uint? - Parse vault ID
(define-read-only (parse-vault-id (id-str (string-ascii 20)))
  (match (string-to-uint? id-str)
    parsed-id (ok parsed-id)
    (err u999)))

;; Clarity 4: buff-to-uint-le - Convert buffer to uint
(define-read-only (buffer-to-number (data-buff (buff 16)))
  (ok (buff-to-uint-le data-buff)))

;; Read-only functions
(define-read-only (get-vault (vault-id uint))
  (ok (map-get? vaults { vault-id: vault-id })))

(define-read-only (get-access-key (vault-id uint) (user principal))
  (ok (map-get? vault-keys { vault-id: vault-id, authorized-principal: user })))

(define-read-only (get-vault-counter)
  (ok (var-get vault-counter)))

(define-read-only (is-authorized (vault-id uint) (user principal))
  (match (map-get? vault-keys { vault-id: vault-id, authorized-principal: user })
    key-data (ok (< stacks-block-time (get expires-at key-data)))
    (ok false)))
