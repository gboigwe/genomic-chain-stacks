;; health-data-nft - Clarity 4
;; NFT for comprehensive health records

(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NFT-NOT-FOUND (err u102))
(define-constant ERR-INVALID-PARAMS (err u104))
(define-constant CONTRACT-OWNER tx-sender)

(define-non-fungible-token health-data-nft uint)
(define-data-var nft-counter uint u0)

(define-map nft-data uint
  {
    patient: principal,
    data-hash: (buff 64),
    record-type: (string-ascii 50),
    created-at: uint,
    updated-at: uint,
    is-encrypted: bool,
    access-level: uint
  }
)

(define-map access-grants { nft-id: uint, grantee: principal }
  { granted-at: uint, expires-at: uint, access-type: (string-ascii 20) }
)

(define-public (mint
    (data-hash (buff 64))
    (record-type (string-ascii 50))
    (is-encrypted bool)
    (access-level uint))
  (let ((new-id (+ (var-get nft-counter) u1)))
    (asserts! (<= access-level u3) ERR-INVALID-PARAMS)
    (try! (nft-mint? health-data-nft new-id tx-sender))
    (map-set nft-data new-id
      {
        patient: tx-sender,
        data-hash: data-hash,
        record-type: record-type,
        created-at: stacks-block-time,
        updated-at: stacks-block-time,
        is-encrypted: is-encrypted,
        access-level: access-level
      })
    (var-set nft-counter new-id)
    (ok new-id)))

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
    (nft-transfer? health-data-nft token-id sender recipient)))

(define-public (grant-access (nft-id uint) (grantee principal) (access-type (string-ascii 20)) (duration uint))
  (let ((owner (unwrap! (nft-get-owner? health-data-nft nft-id) ERR-NFT-NOT-FOUND)))
    (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)
    (ok (map-set access-grants { nft-id: nft-id, grantee: grantee }
      { granted-at: stacks-block-time, expires-at: (+ stacks-block-time duration), access-type: access-type }))))

(define-public (revoke-access (nft-id uint) (grantee principal))
  (let ((owner (unwrap! (nft-get-owner? health-data-nft nft-id) ERR-NFT-NOT-FOUND)))
    (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)
    (ok (map-delete access-grants { nft-id: nft-id, grantee: grantee }))))

(define-public (update-data-hash (nft-id uint) (new-hash (buff 64)))
  (let ((data (unwrap! (map-get? nft-data nft-id) ERR-NFT-NOT-FOUND))
        (owner (unwrap! (nft-get-owner? health-data-nft nft-id) ERR-NFT-NOT-FOUND)))
    (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)
    (ok (map-set nft-data nft-id
      (merge data { data-hash: new-hash, updated-at: stacks-block-time })))))

(define-read-only (get-last-token-id)
  (ok (var-get nft-counter)))

(define-read-only (get-token-uri (token-id uint))
  (ok none))

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? health-data-nft token-id)))

(define-read-only (get-nft-data (nft-id uint))
  (ok (map-get? nft-data nft-id)))

(define-read-only (get-access-grant (nft-id uint) (grantee principal))
  (ok (map-get? access-grants { nft-id: nft-id, grantee: grantee })))

(define-read-only (has-valid-access (nft-id uint) (grantee principal))
  (match (map-get? access-grants { nft-id: nft-id, grantee: grantee })
    grant (ok (< stacks-block-time (get expires-at grant)))
    (ok false)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

;; Clarity 4: int-to-ascii
(define-read-only (format-token-id (token-id uint))
  (ok (int-to-ascii token-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-token-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
