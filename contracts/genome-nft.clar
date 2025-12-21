;; genome-nft.clar - Clarity 4
;; Genomic data NFT (SIP-009)

(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

(define-non-fungible-token genome-data uint)

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))

(define-data-var token-counter uint u0)

(define-public (mint (recipient principal) (data-hash (buff 32)))
  (let
    ((token-id (+ (var-get token-counter) u1)))
    (try! (nft-mint? genome-data token-id recipient))
    (var-set token-counter token-id)
    (ok token-id)))

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
    (nft-transfer? genome-data token-id sender recipient)))

(define-read-only (get-last-token-id)
  (ok (var-get token-counter)))

(define-read-only (get-token-uri (token-id uint))
  (ok none))

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? genome-data token-id)))

;; Clarity 4 features
(define-read-only (validate-owner (owner principal))
  (principal-destruct? owner))

(define-read-only (format-token-id (token-id uint))
  (ok (int-to-ascii token-id)))
