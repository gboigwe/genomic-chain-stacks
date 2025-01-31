;; marketplace.clar

(impl-trait .genetic-data-trait.genetic-data-trait)

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PRICE (err u101))
(define-constant ERR-LISTING-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))

;; Data maps
(define-map listings
    { listing-id: uint }
    {
        owner: principal,
        price: uint,
        data-contract: principal,
        data-id: uint,
        active: bool,
        access-level: uint,
        metadata-hash: (buff 32)
    }
)

(define-map user-purchases
    { user: principal, listing-id: uint }
    {
        purchase-time: uint,
        access-expiry: uint,
        access-level: uint
    }
)

;; Administrative functions
(define-data-var marketplace-admin principal tx-sender)

(define-public (set-admin (new-admin principal))
    (begin
        (asserts! (is-eq tx-sender (var-get marketplace-admin)) ERR-NOT-AUTHORIZED)
        (ok (var-set marketplace-admin new-admin))
    )
)

;; Implement trait functions
(define-public (get-data-details (data-id uint))
    (match (map-get? listings { listing-id: data-id })
        listing (ok {
            owner: (get owner listing),
            price: (get price listing),
            access-level: (get access-level listing),
            metadata-hash: (get metadata-hash listing)
        })
        (err u404)
    )
)

(define-public (verify-access-rights (data-id uint) (user principal))
    (match (map-get? user-purchases { user: user, listing-id: data-id })
        purchase-data (ok (< block-height (get access-expiry purchase-data)))
        (err u404)
    )
)

(define-public (grant-access (data-id uint) (user principal) (access-level uint))
    (begin
        (asserts! (is-eq tx-sender (var-get marketplace-admin)) ERR-NOT-AUTHORIZED)
        (map-set user-purchases
            { user: user, listing-id: data-id }
            {
                purchase-time: block-height,
                access-expiry: (+ block-height u8640),
                access-level: access-level
            }
        )
        (ok true)
    )
)
