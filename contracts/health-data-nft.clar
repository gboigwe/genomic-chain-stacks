;; health-data-nft.clar - Clarity 4
;; Health record NFTs

(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

(define-non-fungible-token health-record uint)

(define-constant ERR-NOT-AUTHORIZED (err u100))

(define-data-var token-counter uint u0)

(define-map token-metadata
  { token-id: uint }
  { record-hash: (buff 32), created-at: uint }
)

(define-public (mint (recipient principal) (record-hash (buff 32)))
  (let
    ((token-id (+ (var-get token-counter) u1)))
    (try! (nft-mint? health-record token-id recipient))
    (map-set token-metadata { token-id: token-id }
      { record-hash: record-hash, created-at: stacks-block-time })
    (var-set token-counter token-id)
    (ok token-id)))

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
    (nft-transfer? health-record token-id sender recipient)))

(define-read-only (get-last-token-id)
  (ok (var-get token-counter)))

(define-read-only (get-token-uri (token-id uint))
  (ok none))

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? health-record token-id)))

;; Clarity 4 features
(define-read-only (validate-owner (owner principal))
  (principal-destruct? owner))

(define-read-only (format-token-id (token-id uint))
  (ok (int-to-utf8 token-id)))
