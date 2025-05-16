;; marketplace.clar
;; Core marketplace for genetic data trading with expanded functionality

(impl-trait .genetic-data-trait.genetic-data-trait)

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PRICE (err u101))
(define-constant ERR-LISTING-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-INVALID-ACCESS-LEVEL (err u104))

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
        metadata-hash: (buff 32),
        created-at: uint,                ;; When listing was created
        updated-at: uint                 ;; When listing was last updated
    }
)

(define-map user-purchases
    { user: principal, listing-id: uint }
    {
        purchase-time: uint,
        access-expiry: uint,
        access-level: uint,
        transaction-id: (buff 32)        ;; Transaction ID for the purchase
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
    (metadata-hash (buff 32)))
    
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
                access-level: access-level,
                metadata-hash: metadata-hash,
                created-at: stacks-block-height,
                updated-at: stacks-block-height
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
                purchase-time: stacks-block-height,
                access-expiry: (+ stacks-block-height u8640),
                access-level: (get access-level listing),
                transaction-id: 0x00
            }
        )
        (ok true)
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
        purchase-data (ok (< stacks-block-height (get access-expiry purchase-data)))
        (err u404)
    )
)

(define-public (grant-access (data-id uint) (user principal) (access-level uint))
    (begin
        (asserts! (is-eq tx-sender (var-get marketplace-admin)) ERR-NOT-AUTHORIZED)
        (map-set user-purchases
            { user: user, listing-id: data-id }
            {
                purchase-time: stacks-block-height,
                access-expiry: (+ stacks-block-height u8640),
                access-level: access-level,
                transaction-id: 0x00
            }
        )
        (ok true)
    )
)

;; Query functions
(define-read-only (get-listing (listing-id uint))
    (map-get? listings { listing-id: listing-id })
)

(define-read-only (get-user-purchase (user principal) (listing-id uint))
    (map-get? user-purchases { user: user, listing-id: listing-id })
)
