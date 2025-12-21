;; research-marketplace.clar - Clarity 4
;; Anonymous data marketplace for research

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-LISTING-NOT-FOUND (err u101))

(define-data-var listing-counter uint u0)

(define-map data-listings
  { listing-id: uint }
  {
    seller: principal,
    data-hash: (buff 32),
    price: uint,
    anonymization-level: uint,
    created-at: uint,
    is-sold: bool,
    buyer: (optional principal)
  }
)

(define-public (list-data
    (data-hash (buff 32))
    (price uint)
    (anonymization-level uint))
  (let
    ((new-id (+ (var-get listing-counter) u1)))
    (map-set data-listings { listing-id: new-id }
      {
        seller: tx-sender,
        data-hash: data-hash,
        price: price,
        anonymization-level: anonymization-level,
        created-at: stacks-block-time,
        is-sold: false,
        buyer: none
      })
    (var-set listing-counter new-id)
    (ok new-id)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-seller (seller principal))
  (principal-destruct? seller))

;; Clarity 4: int-to-ascii
(define-read-only (format-listing-id (listing-id uint))
  (ok (int-to-ascii listing-id)))

(define-read-only (get-listing (listing-id uint))
  (ok (map-get? data-listings { listing-id: listing-id })))
