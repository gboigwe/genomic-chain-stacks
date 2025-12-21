;; genome-nft - Clarity 4
;; NFT representation of genomic data ownership

;; (impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait) ;; Commented for local testing

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NFT-EXISTS (err u101))
(define-constant ERR-NFT-NOT-FOUND (err u102))
(define-constant ERR-INVALID-OWNER (err u103))

(define-non-fungible-token genome-nft uint)
(define-data-var nft-counter uint u0)

(define-map nft-metadata uint
  {
    data-hash: (buff 64),
    genome-type: (string-ascii 50),
    sample-date: uint,
    quality-score: uint,
    is-verified: bool,
    metadata-uri: (string-utf8 256)
  }
)

(define-map nft-royalties uint
  {
    original-owner: principal,
    royalty-percentage: uint
  }
)

(define-public (mint
    (data-hash (buff 64))
    (genome-type (string-ascii 50))
    (sample-date uint)
    (quality-score uint)
    (metadata-uri (string-utf8 256)))
  (let
    ((new-id (+ (var-get nft-counter) u1)))
    (asserts! (<= quality-score u100) (err u104))
    (try! (nft-mint? genome-nft new-id tx-sender))
    (map-set nft-metadata new-id
      {
        data-hash: data-hash,
        genome-type: genome-type,
        sample-date: sample-date,
        quality-score: quality-score,
        is-verified: false,
        metadata-uri: metadata-uri
      })
    (map-set nft-royalties new-id
      {
        original-owner: tx-sender,
        royalty-percentage: u10
      })
    (var-set nft-counter new-id)
    (ok new-id)))

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (nft-get-owner? genome-nft token-id)) ERR-NFT-NOT-FOUND)
    (nft-transfer? genome-nft token-id sender recipient)))

(define-public (verify-nft (token-id uint))
  (let ((metadata (unwrap! (map-get? nft-metadata token-id) ERR-NFT-NOT-FOUND)))
    (ok (map-set nft-metadata token-id (merge metadata { is-verified: true })))))

(define-read-only (get-last-token-id)
  (ok (var-get nft-counter)))

(define-read-only (get-token-uri (token-id uint))
  (ok (some (get metadata-uri (unwrap! (map-get? nft-metadata token-id) ERR-NFT-NOT-FOUND)))))

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? genome-nft token-id)))

(define-read-only (get-metadata (token-id uint))
  (ok (map-get? nft-metadata token-id)))

(define-read-only (get-royalty-info (token-id uint))
  (ok (map-get? nft-royalties token-id)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-owner (owner principal))
  (principal-destruct? owner))

;; Clarity 4: int-to-ascii
(define-read-only (format-token-id (token-id uint))
  (ok (int-to-ascii token-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-token-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
