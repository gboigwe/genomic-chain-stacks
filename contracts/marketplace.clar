;; marketplace.clar
;; Core marketplace for genetic data trading with expanded functionality

(impl-trait .genetic-data-trait.genetic-data-trait)

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PRICE (err u101))
(define-constant ERR-LISTING-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-INVALID-ACCESS-LEVEL (err u104))
(define-constant ERR-NOT-FOUND (err u105))

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
        created-at: uint,
        updated-at: uint
    }
)

(define-map user-purchases
    { user: principal, listing-id: uint }
    {
        purchase-time: uint,
        access-expiry: uint,
        access-level: uint,
        transaction-id: (buff 32),
        purchase-price: uint             ;; Price paid for the purchase
    }
)

;; Price tiers for different access levels
(define-map access-level-pricing
    { listing-id: uint, access-level: uint }
    {
        price: uint                      ;; Price for this access level
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
        (asserts! (> access-level u0) ERR-INVALID-ACCESS-LEVEL)
        (asserts! (<= access-level u3) ERR-INVALID-ACCESS-LEVEL)
        
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
        
        ;; Set up default pricing tier for this access level
        (map-set access-level-pricing
            { listing-id: listing-id, access-level: access-level }
            { price: price }
        )
        
        (ok true)
    )
)

;; Set tiered pricing for different access levels
(define-public (set-access-level-price (listing-id uint) (access-level uint) (price uint))
    (let ((listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR-LISTING-NOT-FOUND)))
        ;; Only the owner can set prices
        (asserts! (is-eq tx-sender (get owner listing)) ERR-NOT-AUTHORIZED)
        (asserts! (> price u0) ERR-INVALID-PRICE)
        (asserts! (> access-level u0) ERR-INVALID-ACCESS-LEVEL)
        (asserts! (<= access-level (get access-level listing)) ERR-INVALID-ACCESS-LEVEL)
        
        (map-set access-level-pricing
            { listing-id: listing-id, access-level: access-level }
            { price: price }
        )
        
        (ok true)
    )
)

;; Get price for specific access level
(define-read-only (get-access-level-price (listing-id uint) (access-level uint))
    (match (map-get? access-level-pricing { listing-id: listing-id, access-level: access-level })
        price-info (ok (get price price-info))
        ;; Fall back to listing default price
        (match (map-get? listings { listing-id: listing-id })
            listing (ok (get price listing))
            (err ERR-LISTING-NOT-FOUND)
        )
    )
)

;; Update listing status
(define-public (update-listing-status (listing-id uint) (active bool))
    (let ((listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR-LISTING-NOT-FOUND)))
        ;; Only the owner can update status
        (asserts! (is-eq tx-sender (get owner listing)) ERR-NOT-AUTHORIZED)
        
        (map-set listings
            { listing-id: listing-id }
            (merge listing { 
                active: active,
                updated-at: stacks-block-height
            })
        )
        
        (ok true)
    )
)

(define-public (purchase-listing (listing-id uint) (access-level uint))
    (let (
        (listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR-LISTING-NOT-FOUND))
        (owner (get owner listing))
    )
        (asserts! (get active listing) ERR-LISTING-NOT-FOUND)
        (asserts! (> access-level u0) ERR-INVALID-ACCESS-LEVEL)
        (asserts! (<= access-level (get access-level listing)) ERR-INVALID-ACCESS-LEVEL)
        
        (let ((price (unwrap! (get-access-level-price listing-id access-level) ERR-INVALID-PRICE)))
            (asserts! (>= (stx-get-balance tx-sender) price) ERR-INSUFFICIENT-BALANCE)
            (try! (stx-transfer? price tx-sender owner))
            
            (map-set user-purchases
                { user: tx-sender, listing-id: listing-id }
                {
                    purchase-time: stacks-block-height,
                    access-expiry: (+ stacks-block-height u8640),
                    access-level: access-level,
                    transaction-id: 0x00,
                    purchase-price: price
                }
            )
            
            (ok true)
        )
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
                transaction-id: 0x00,
                purchase-price: u0       ;; Admin granted access has no price
            }
        )
        (ok true)
    )
)

;; Extend user access
(define-public (extend-access (listing-id uint) (user principal) (duration uint))
    (let (
        (listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR-LISTING-NOT-FOUND))
        (purchase (unwrap! (map-get? user-purchases { user: user, listing-id: listing-id }) ERR-NOT-FOUND))
    )
        ;; Only owner or admin can extend access
        (asserts! (or 
            (is-eq tx-sender (get owner listing))
            (is-eq tx-sender (var-get marketplace-admin))
        ) ERR-NOT-AUTHORIZED)
        
        ;; Update the purchase record with extended expiry
        (map-set user-purchases
            { user: user, listing-id: listing-id }
            (merge purchase {
                access-expiry: (+ (get access-expiry purchase) duration)
            })
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
