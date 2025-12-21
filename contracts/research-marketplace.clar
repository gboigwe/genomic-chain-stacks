;; research-marketplace - Clarity 4
;; Marketplace for genomic data sharing with researchers

(define-constant ERR-LISTING-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u102))

(define-map data-listings uint
  {
    provider: principal,
    data-type: (string-ascii 50),
    price: uint,
    sample-size: uint,
    created-at: uint,
    is-available: bool,
    quality-score: uint,
    access-restrictions: (list 5 (string-ascii 50))
  }
)

(define-map purchase-orders uint
  {
    listing-id: uint,
    buyer: principal,
    price-paid: uint,
    purchased-at: uint,
    access-granted: bool,
    license-type: (string-ascii 50)
  }
)

(define-map data-licenses uint
  {
    purchase-id: uint,
    license-terms: (string-utf8 500),
    duration: uint,
    expires-at: uint,
    usage-restrictions: (list 10 (string-ascii 50)),
    is-active: bool
  }
)

(define-map provider-ratings uint
  {
    provider: principal,
    rater: principal,
    rating: uint,
    comment: (string-utf8 300),
    rated-at: uint,
    verified-purchase: bool
  }
)

(define-map escrow-accounts uint
  {
    purchase-id: uint,
    amount: uint,
    deposited-by: principal,
    release-condition: (string-ascii 50),
    is-released: bool,
    deposited-at: uint
  }
)

(define-data-var listing-counter uint u0)
(define-data-var order-counter uint u0)
(define-data-var license-counter uint u0)
(define-data-var rating-counter uint u0)
(define-data-var escrow-counter uint u0)

(define-public (create-listing
    (data-type (string-ascii 50))
    (price uint)
    (sample-size uint)
    (quality-score uint)
    (access-restrictions (list 5 (string-ascii 50))))
  (let ((listing-id (+ (var-get listing-counter) u1)))
    (map-set data-listings listing-id
      {
        provider: tx-sender,
        data-type: data-type,
        price: price,
        sample-size: sample-size,
        created-at: stacks-block-time,
        is-available: true,
        quality-score: quality-score,
        access-restrictions: access-restrictions
      })
    (var-set listing-counter listing-id)
    (ok listing-id)))

(define-public (purchase-data
    (listing-id uint)
    (license-type (string-ascii 50)))
  (let ((listing (unwrap! (map-get? data-listings listing-id) ERR-LISTING-NOT-FOUND))
        (order-id (+ (var-get order-counter) u1)))
    (asserts! (get is-available listing) ERR-LISTING-NOT-FOUND)
    (map-set purchase-orders order-id
      {
        listing-id: listing-id,
        buyer: tx-sender,
        price-paid: (get price listing),
        purchased-at: stacks-block-time,
        access-granted: false,
        license-type: license-type
      })
    (var-set order-counter order-id)
    (ok order-id)))

(define-public (issue-license
    (purchase-id uint)
    (license-terms (string-utf8 500))
    (duration uint)
    (usage-restrictions (list 10 (string-ascii 50))))
  (let ((license-id (+ (var-get license-counter) u1)))
    (map-set data-licenses license-id
      {
        purchase-id: purchase-id,
        license-terms: license-terms,
        duration: duration,
        expires-at: (+ stacks-block-time duration),
        usage-restrictions: usage-restrictions,
        is-active: true
      })
    (var-set license-counter license-id)
    (ok license-id)))

(define-public (rate-provider
    (provider principal)
    (rating uint)
    (comment (string-utf8 300))
    (verified-purchase bool))
  (let ((rating-id (+ (var-get rating-counter) u1)))
    (map-set provider-ratings rating-id
      {
        provider: provider,
        rater: tx-sender,
        rating: rating,
        comment: comment,
        rated-at: stacks-block-time,
        verified-purchase: verified-purchase
      })
    (var-set rating-counter rating-id)
    (ok rating-id)))

(define-read-only (get-listing (listing-id uint))
  (ok (map-get? data-listings listing-id)))

(define-read-only (get-purchase-order (order-id uint))
  (ok (map-get? purchase-orders order-id)))

(define-read-only (get-license (license-id uint))
  (ok (map-get? data-licenses license-id)))

(define-read-only (get-rating (rating-id uint))
  (ok (map-get? provider-ratings rating-id)))

(define-read-only (validate-provider (provider principal))
  (principal-destruct? provider))

(define-read-only (format-listing-id (listing-id uint))
  (ok (int-to-ascii listing-id)))

(define-read-only (parse-listing-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
