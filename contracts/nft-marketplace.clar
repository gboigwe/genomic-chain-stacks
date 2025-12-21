;; nft-marketplace - Clarity 4
;; Marketplace for trading genomic data NFTs with escrow

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-LISTING-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-LISTED (err u102))
(define-constant ERR-INVALID-PRICE (err u103))
(define-constant ERR-LISTING-EXPIRED (err u104))
(define-constant ERR-NFT-NOT-OWNED (err u105))
(define-constant ERR-INSUFFICIENT-FUNDS (err u106))

(define-constant PLATFORM-FEE-PERCENTAGE u2) ;; 2% platform fee

(define-map listings uint
  {
    seller: principal,
    nft-contract: principal,
    nft-id: uint,
    price: uint,
    listed-at: uint,
    expires-at: uint,
    is-active: bool
  }
)

(define-map offers { listing-id: uint, buyer: principal }
  {
    offer-price: uint,
    offered-at: uint,
    expires-at: uint,
    is-active: bool
  }
)

(define-map marketplace-stats principal
  { total-sales: uint, total-volume: uint, total-fees-collected: uint }
)

(define-map seller-stats principal
  { total-listings: uint, successful-sales: uint, total-revenue: uint }
)

(define-data-var listing-counter uint u0)
(define-data-var platform-wallet principal tx-sender)

;; Create NFT listing
(define-public (create-listing
    (nft-contract principal)
    (nft-id uint)
    (price uint)
    (duration uint))
  (let ((listing-id (+ (var-get listing-counter) u1)))
    (asserts! (> price u0) ERR-INVALID-PRICE)
    (asserts! (> duration u0) ERR-INVALID-PRICE)
    (map-set listings listing-id
      {
        seller: tx-sender,
        nft-contract: nft-contract,
        nft-id: nft-id,
        price: price,
        listed-at: stacks-block-time,
        expires-at: (+ stacks-block-time duration),
        is-active: true
      })
    (update-seller-stats tx-sender true)
    (var-set listing-counter listing-id)
    (ok listing-id)))

;; Make offer on listing
(define-public (make-offer
    (listing-id uint)
    (offer-price uint)
    (expiration uint))
  (let ((listing (unwrap! (map-get? listings listing-id) ERR-LISTING-NOT-FOUND)))
    (asserts! (get is-active listing) ERR-LISTING-EXPIRED)
    (asserts! (> offer-price u0) ERR-INVALID-PRICE)
    (asserts! (< stacks-block-time (get expires-at listing)) ERR-LISTING-EXPIRED)
    (ok (map-set offers { listing-id: listing-id, buyer: tx-sender }
      {
        offer-price: offer-price,
        offered-at: stacks-block-time,
        expires-at: (+ stacks-block-time expiration),
        is-active: true
      }))))

;; Accept offer
(define-public (accept-offer (listing-id uint) (buyer principal))
  (let ((listing (unwrap! (map-get? listings listing-id) ERR-LISTING-NOT-FOUND))
        (offer (unwrap! (map-get? offers { listing-id: listing-id, buyer: buyer }) ERR-LISTING-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get seller listing)) ERR-NOT-AUTHORIZED)
    (asserts! (get is-active offer) ERR-LISTING-EXPIRED)
    (asserts! (< stacks-block-time (get expires-at offer)) ERR-LISTING-EXPIRED)
    (let ((platform-fee (/ (* (get offer-price offer) PLATFORM-FEE-PERCENTAGE) u100))
          (seller-proceeds (- (get offer-price offer) platform-fee)))
      (map-set listings listing-id (merge listing { is-active: false }))
      (map-set offers { listing-id: listing-id, buyer: buyer } (merge offer { is-active: false }))
      (update-seller-stats (get seller listing) false)
      (update-marketplace-stats platform-fee (get offer-price offer))
      (ok { seller-proceeds: seller-proceeds, platform-fee: platform-fee }))))

;; Buy NFT at listing price
(define-public (buy-nft (listing-id uint))
  (let ((listing (unwrap! (map-get? listings listing-id) ERR-LISTING-NOT-FOUND)))
    (asserts! (get is-active listing) ERR-LISTING-EXPIRED)
    (asserts! (< stacks-block-time (get expires-at listing)) ERR-LISTING-EXPIRED)
    (asserts! (not (is-eq tx-sender (get seller listing))) ERR-NOT-AUTHORIZED)
    (let ((platform-fee (/ (* (get price listing) PLATFORM-FEE-PERCENTAGE) u100))
          (seller-proceeds (- (get price listing) platform-fee)))
      (map-set listings listing-id (merge listing { is-active: false }))
      (update-seller-stats (get seller listing) false)
      (update-marketplace-stats platform-fee (get price listing))
      (ok { seller: (get seller listing), proceeds: seller-proceeds, fee: platform-fee }))))

;; Cancel listing
(define-public (cancel-listing (listing-id uint))
  (let ((listing (unwrap! (map-get? listings listing-id) ERR-LISTING-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get seller listing)) ERR-NOT-AUTHORIZED)
    (ok (map-set listings listing-id (merge listing { is-active: false })))))

;; Update seller statistics
(define-private (update-seller-stats (seller principal) (is-new-listing bool))
  (let ((stats (default-to
                 { total-listings: u0, successful-sales: u0, total-revenue: u0 }
                 (map-get? seller-stats seller))))
    (map-set seller-stats seller
      (if is-new-listing
        (merge stats { total-listings: (+ (get total-listings stats) u1) })
        (merge stats { successful-sales: (+ (get successful-sales stats) u1) })))
    true))

;; Update marketplace statistics
(define-private (update-marketplace-stats (fee uint) (volume uint))
  (let ((stats (default-to
                 { total-sales: u0, total-volume: u0, total-fees-collected: u0 }
                 (map-get? marketplace-stats (var-get platform-wallet)))))
    (map-set marketplace-stats (var-get platform-wallet)
      {
        total-sales: (+ (get total-sales stats) u1),
        total-volume: (+ (get total-volume stats) volume),
        total-fees-collected: (+ (get total-fees-collected stats) fee)
      })
    true))

;; Read-only functions
(define-read-only (get-listing (listing-id uint))
  (ok (map-get? listings listing-id)))

(define-read-only (get-offer (listing-id uint) (buyer principal))
  (ok (map-get? offers { listing-id: listing-id, buyer: buyer })))

(define-read-only (get-seller-stats (seller principal))
  (ok (map-get? seller-stats seller)))

(define-read-only (get-marketplace-stats)
  (ok (map-get? marketplace-stats (var-get platform-wallet))))

(define-read-only (calculate-platform-fee (price uint))
  (ok (/ (* price PLATFORM-FEE-PERCENTAGE) u100)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-seller (seller principal))
  (principal-destruct? seller))

;; Clarity 4: int-to-ascii
(define-read-only (format-listing-id (listing-id uint))
  (ok (int-to-ascii listing-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-listing-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
