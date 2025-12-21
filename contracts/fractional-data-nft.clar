;; fractional-data-nft - Clarity 4
;; Fractionalized ownership of genomic data NFTs

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NFT-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-FRACTIONALIZED (err u102))
(define-constant ERR-INVALID-SHARES (err u103))
(define-constant ERR-INSUFFICIENT-SHARES (err u104))
(define-constant ERR-NOT-FRACTIONALIZED (err u105))

(define-constant MAX-SHARES u1000000) ;; Maximum fractional shares

(define-map fractionalized-nfts uint
  {
    original-nft-id: uint,
    original-owner: principal,
    total-shares: uint,
    shares-sold: uint,
    share-price: uint,
    fractionalized-at: uint,
    is-active: bool
  }
)

(define-map shareholder-balances { nft-id: uint, holder: principal }
  { shares: uint, acquired-at: uint }
)

(define-map share-transfer-history uint
  {
    nft-id: uint,
    from: principal,
    to: principal,
    shares: uint,
    price: uint,
    timestamp: uint
  }
)

(define-map voting-rights { nft-id: uint, holder: principal }
  { voting-power: uint, has-voted: bool }
)

(define-data-var fraction-counter uint u0)
(define-data-var transfer-counter uint u0)

;; Fractionalize NFT into shares
(define-public (fractionalize-nft
    (original-nft-id uint)
    (total-shares uint)
    (share-price uint))
  (let ((fraction-id (+ (var-get fraction-counter) u1)))
    (asserts! (> total-shares u0) ERR-INVALID-SHARES)
    (asserts! (<= total-shares MAX-SHARES) ERR-INVALID-SHARES)
    (asserts! (> share-price u0) ERR-INVALID-SHARES)
    (map-set fractionalized-nfts fraction-id
      {
        original-nft-id: original-nft-id,
        original-owner: tx-sender,
        total-shares: total-shares,
        shares-sold: u0,
        share-price: share-price,
        fractionalized-at: stacks-block-time,
        is-active: true
      })
    (map-set shareholder-balances { nft-id: fraction-id, holder: tx-sender }
      { shares: total-shares, acquired-at: stacks-block-time })
    (var-set fraction-counter fraction-id)
    (ok fraction-id)))

;; Buy fractional shares
(define-public (buy-shares (nft-id uint) (shares-to-buy uint))
  (let ((fraction (unwrap! (map-get? fractionalized-nfts nft-id) ERR-NFT-NOT-FOUND))
        (owner-balance (unwrap! (map-get? shareholder-balances
                                         { nft-id: nft-id, holder: (get original-owner fraction) })
                               ERR-NOT-AUTHORIZED)))
    (asserts! (get is-active fraction) ERR-NOT-FRACTIONALIZED)
    (asserts! (>= (get shares owner-balance) shares-to-buy) ERR-INSUFFICIENT-SHARES)
    (let ((buyer-balance (default-to { shares: u0, acquired-at: u0 }
                                     (map-get? shareholder-balances { nft-id: nft-id, holder: tx-sender }))))
      ;; Update seller balance
      (map-set shareholder-balances { nft-id: nft-id, holder: (get original-owner fraction) }
        (merge owner-balance { shares: (- (get shares owner-balance) shares-to-buy) }))
      ;; Update buyer balance
      (map-set shareholder-balances { nft-id: nft-id, holder: tx-sender }
        { shares: (+ (get shares buyer-balance) shares-to-buy),
          acquired-at: stacks-block-time })
      ;; Record transfer
      (record-transfer nft-id (get original-owner fraction) tx-sender shares-to-buy (get share-price fraction))
      (ok shares-to-buy))))

;; Transfer shares between holders
(define-public (transfer-shares
    (nft-id uint)
    (recipient principal)
    (shares uint))
  (let ((sender-balance (unwrap! (map-get? shareholder-balances { nft-id: nft-id, holder: tx-sender })
                                ERR-INSUFFICIENT-SHARES))
        (recipient-balance (default-to { shares: u0, acquired-at: u0 }
                                      (map-get? shareholder-balances { nft-id: nft-id, holder: recipient }))))
    (asserts! (>= (get shares sender-balance) shares) ERR-INSUFFICIENT-SHARES)
    (map-set shareholder-balances { nft-id: nft-id, holder: tx-sender }
      (merge sender-balance { shares: (- (get shares sender-balance) shares) }))
    (map-set shareholder-balances { nft-id: nft-id, holder: recipient }
      { shares: (+ (get shares recipient-balance) shares),
        acquired-at: stacks-block-time })
    (record-transfer nft-id tx-sender recipient shares u0)
    (ok true)))

;; Reunify NFT (buy back all shares)
(define-public (reunify-nft (nft-id uint))
  (let ((fraction (unwrap! (map-get? fractionalized-nfts nft-id) ERR-NFT-NOT-FOUND))
        (owner-balance (unwrap! (map-get? shareholder-balances
                                         { nft-id: nft-id, holder: tx-sender })
                               ERR-NOT-AUTHORIZED)))
    (asserts! (is-eq tx-sender (get original-owner fraction)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get shares owner-balance) (get total-shares fraction)) ERR-INSUFFICIENT-SHARES)
    (ok (map-set fractionalized-nfts nft-id (merge fraction { is-active: false })))))

;; Record share transfer
(define-private (record-transfer
    (nft-id uint)
    (from principal)
    (to principal)
    (shares uint)
    (price uint))
  (let ((transfer-id (+ (var-get transfer-counter) u1)))
    (map-set share-transfer-history transfer-id
      {
        nft-id: nft-id,
        from: from,
        to: to,
        shares: shares,
        price: price,
        timestamp: stacks-block-time
      })
    (var-set transfer-counter transfer-id)
    true))

;; Read-only functions
(define-read-only (get-fractionalized-nft (nft-id uint))
  (ok (map-get? fractionalized-nfts nft-id)))

(define-read-only (get-shareholder-balance (nft-id uint) (holder principal))
  (ok (map-get? shareholder-balances { nft-id: nft-id, holder: holder })))

(define-read-only (get-transfer-history (transfer-id uint))
  (ok (map-get? share-transfer-history transfer-id)))

(define-read-only (calculate-ownership-percentage (nft-id uint) (holder principal))
  (let ((fraction (unwrap! (map-get? fractionalized-nfts nft-id) ERR-NFT-NOT-FOUND))
        (balance (unwrap! (map-get? shareholder-balances { nft-id: nft-id, holder: holder })
                         ERR-INSUFFICIENT-SHARES)))
    (ok (/ (* (get shares balance) u100) (get total-shares fraction)))))

;; Clarity 4: principal-destruct?
(define-read-only (validate-holder (holder principal))
  (principal-destruct? holder))

;; Clarity 4: int-to-ascii
(define-read-only (format-nft-id (nft-id uint))
  (ok (int-to-ascii nft-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-nft-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
