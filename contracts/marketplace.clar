;; marketplace.clar
;; Core marketplace functionality for genetic data trading

(use-trait genetic-data-trait 'SP000000000000000000002Q6VF78.genetic-data.genetic-data-trait)

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
        access-level: uint
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

;; Listing management
(define-public (create-listing 
    (listing-id uint) 
    (price uint)
    (data-contract principal)
    (data-id uint)
    (access-level uint)
    )
    (begin
        (asserts! (> price u0) ERR-INVALID-PRICE)
        (map-set listings
            { listing-id: listing-id }
            {
                owner: tx-sender,
                price: price,
                data-contract: data-contract,
                data-id: data-id,
                active: true,
                access-level: access-level
            }
        )
        (ok true)
    )
)

(define-public (purchase-listing (listing-id uint))
    (let (
        (listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR-LISTING-NOT-FOUND))
        (price (get price listing))
        (owner (get owner listing))
    )
        (asserts! (get active listing) ERR-LISTING-NOT-FOUND)
        (asserts! (>= (stx-get-balance tx-sender) price) ERR-INSUFFICIENT-BALANCE)
        (try! (stx-transfer? price tx-sender owner))
        (map-set user-purchases
            { user: tx-sender, listing-id: listing-id }
            {
                purchase-time: block-height,
                access-expiry: (+ block-height u8640),
                access-level: (get access-level listing)
            }
        )
        (ok true)
    )
)

;; Access verification
(define-read-only (verify-access (user principal) (listing-id uint))
    (match (map-get? user-purchases { user: user, listing-id: listing-id })
        purchase-data (ok (< block-height (get access-expiry purchase-data)))
        ERR-NOT-AUTHORIZED
    )
)

;; Query functions
(define-read-only (get-listing (listing-id uint))
    (map-get? listings { listing-id: listing-id })
)

(define-read-only (get-user-purchase (user principal) (listing-id uint))
    (map-get? user-purchases { user: user, listing-id: listing-id })
)
