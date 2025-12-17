;; marketplace.clar - Clarity 4
;; Core marketplace for genetic data trading with expanded functionality

;; Import trait
(impl-trait .genetic-data-trait.genetic-data-trait)

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PRICE (err u101))
(define-constant ERR-LISTING-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-INVALID-ACCESS-LEVEL (err u104))
(define-constant ERR-NO-VERIFIED-PROOFS (err u105))
(define-constant ERR-NO-VALID-CONSENT (err u106))
(define-constant ERR-PAYMENT-FAILED (err u107))
(define-constant ERR-ESCROW-EXISTS (err u108))
(define-constant ERR-ESCROW-NOT-FOUND (err u109))
(define-constant ERR-EXPIRED (err u110))
(define-constant ERR-NOT-FOUND (err u111))

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
        requires-verification: bool,
        platform-fee-percent: uint,
        created-at: uint,                ;; Clarity 4: Unix timestamp
        updated-at: uint                 ;; Clarity 4: Unix timestamp
    }
)

(define-map user-purchases
    { user: principal, listing-id: uint }
    {
        purchase-time: uint,              ;; Clarity 4: Unix timestamp
        access-expiry: uint,              ;; Clarity 4: Unix timestamp
        access-level: uint,
        transaction-id: (buff 32),
        purchase-price: uint
    }
)

(define-map access-level-pricing
    { listing-id: uint, access-level: uint }
    {
        price: uint
    }
)

(define-map purchase-escrows
    { escrow-id: uint }
    {
        listing-id: uint,
        buyer: principal,
        amount: uint,
        created-at: uint,                 ;; Clarity 4: Unix timestamp
        expires-at: uint,                 ;; Clarity 4: Unix timestamp  
        released: bool,
        refunded: bool,
        access-level: uint
    }
)

(define-data-var next-escrow-id uint u1)
(define-data-var platform-fee-percent uint u250)
(define-data-var platform-address principal tx-sender)
(define-data-var marketplace-admin principal tx-sender)

(define-public (set-admin (new-admin principal))
    (begin
        (asserts! (is-eq tx-sender (var-get marketplace-admin)) ERR-NOT-AUTHORIZED)
        (ok (var-set marketplace-admin new-admin))
    )
)

(define-public (set-platform-fee (new-fee-percent uint))
    (begin
        (asserts! (is-eq tx-sender (var-get marketplace-admin)) ERR-NOT-AUTHORIZED)
        (asserts! (<= new-fee-percent u1000) ERR-INVALID-PRICE)
        (ok (var-set platform-fee-percent new-fee-percent))
    )
)

(define-public (set-platform-address (new-address principal))
    (begin
        (asserts! (is-eq tx-sender (var-get marketplace-admin)) ERR-NOT-AUTHORIZED)
        (ok (var-set platform-address new-address))
    )
)

(define-public (create-listing
    (listing-id uint)
    (price uint)
    (data-contract principal)
    (data-id uint)
    (access-level uint)
    (metadata-hash (buff 32))
    (requires-verification bool))

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
                requires-verification: requires-verification,
                platform-fee-percent: (var-get platform-fee-percent),
                created-at: stacks-block-time,    ;; Clarity 4: Unix timestamp
                updated-at: stacks-block-time     ;; Clarity 4: Unix timestamp
            }
        )

        (map-set access-level-pricing
            { listing-id: listing-id, access-level: access-level }
            { price: price }
        )

        (ok true)
    )
)

(define-public (set-access-level-price (listing-id uint) (access-level uint) (price uint))
    (let ((listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR-LISTING-NOT-FOUND)))
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

(define-public (update-listing-status (listing-id uint) (active bool))
    (let ((listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR-LISTING-NOT-FOUND)))
        (asserts! (is-eq tx-sender (get owner listing)) ERR-NOT-AUTHORIZED)

        (map-set listings
            { listing-id: listing-id }
            (merge listing {
                active: active,
                updated-at: stacks-block-time     ;; Clarity 4: Unix timestamp
            })
        )

        (ok true)
    )
)

(define-public (verify-purchase-eligibility (listing-id uint) (access-level uint))
    (let (
        (listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR-LISTING-NOT-FOUND))
        (data-id (get data-id listing))
    )
        (asserts! (get active listing) ERR-LISTING-NOT-FOUND)
        (asserts! (> access-level u0) ERR-INVALID-ACCESS-LEVEL)
        (asserts! (<= access-level (get access-level listing)) ERR-INVALID-ACCESS-LEVEL)

        (if (get requires-verification listing)
            (begin
                (let ((verification-result (contract-call? .verification check-verified-proof data-id u1)))
                    (asserts! (is-ok verification-result) ERR-NO-VERIFIED-PROOFS)
                    (let ((proof-list (unwrap! verification-result ERR-NO-VERIFIED-PROOFS)))
                        (asserts! (> (len proof-list) u0) ERR-NO-VERIFIED-PROOFS)
                    )
                )
            )
            true
        )

        (let ((consent-result (contract-call? .compliance check-consent-validity data-id u1)))
            (asserts! (is-ok consent-result) ERR-NO-VALID-CONSENT)
            (let ((is-valid (unwrap! consent-result ERR-NO-VALID-CONSENT)))
                (asserts! is-valid ERR-NO-VALID-CONSENT)
            )
        )

        (ok true)
    )
)

(define-read-only (get-access-level-price (listing-id uint) (access-level uint))
    (match (map-get? access-level-pricing { listing-id: listing-id, access-level: access-level })
        price-info (ok (get price price-info))
        (match (map-get? listings { listing-id: listing-id })
            listing (ok (get price listing))
            (err ERR-LISTING-NOT-FOUND)
        )
    )
)

(define-public (create-purchase-escrow (listing-id uint) (access-level uint))
    (let (
        (listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR-LISTING-NOT-FOUND))
        (escrow-id (var-get next-escrow-id))
    )
        (try! (verify-purchase-eligibility listing-id access-level))

        (let ((price (unwrap! (get-access-level-price listing-id access-level) ERR-INVALID-PRICE)))
            (asserts! (>= (stx-get-balance tx-sender) price) ERR-INSUFFICIENT-BALANCE)
            (var-set next-escrow-id (+ escrow-id u1))

            (map-set purchase-escrows
                { escrow-id: escrow-id }
                {
                    listing-id: listing-id,
                    buyer: tx-sender,
                    amount: price,
                    created-at: stacks-block-time,                  ;; Clarity 4: Unix timestamp
                    expires-at: (+ stacks-block-time u86400),       ;; Clarity 4: 24 hours in seconds
                    released: false,
                    refunded: false,
                    access-level: access-level
                }
            )

            (ok escrow-id)
        )
    )
)

(define-public (complete-purchase (escrow-id uint) (tx-id (buff 32)))
    (let (
        (escrow (unwrap! (map-get? purchase-escrows { escrow-id: escrow-id }) ERR-ESCROW-NOT-FOUND))
        (listing (unwrap! (map-get? listings { listing-id: (get listing-id escrow) }) ERR-LISTING-NOT-FOUND))
    )
        (asserts! (not (get released escrow)) ERR-NOT-AUTHORIZED)
        (asserts! (not (get refunded escrow)) ERR-NOT-AUTHORIZED)
        (asserts! (< stacks-block-time (get expires-at escrow)) ERR-EXPIRED)  ;; Clarity 4

        (map-set purchase-escrows
            { escrow-id: escrow-id }
            (merge escrow { released: true })
        )

        (let (
            (amount (get amount escrow))
            (fee-percent (get platform-fee-percent listing))
            (fee-amount (/ (* amount fee-percent) u10000))
            (seller-amount (- amount fee-amount))
        )
            (map-set user-purchases
                { user: (get buyer escrow), listing-id: (get listing-id escrow) }
                {
                    purchase-time: stacks-block-time,                ;; Clarity 4: Unix timestamp
                    access-expiry: (+ stacks-block-time u2592000),   ;; Clarity 4: ~30 days in seconds
                    access-level: (get access-level escrow),
                    transaction-id: tx-id,
                    purchase-price: amount
                }
            )

            (let ((log-result (contract-call? .compliance log-data-access
                (get data-id listing)
                u1
                tx-id
            )))
                (asserts! (is-ok log-result) ERR-PAYMENT-FAILED)
            )

            (let ((access-result (contract-call? .genetic-data grant-access
                (get data-id listing)
                (get buyer escrow)
                (get access-level escrow)
            )))
                (asserts! (is-ok access-result) ERR-PAYMENT-FAILED)
            )

            (ok true)
        )
    )
)

(define-public (refund-escrow (escrow-id uint))
    (let (
        (escrow (unwrap! (map-get? purchase-escrows { escrow-id: escrow-id }) ERR-ESCROW-NOT-FOUND))
    )
        (asserts! (not (get released escrow)) ERR-NOT-AUTHORIZED)
        (asserts! (not (get refunded escrow)) ERR-NOT-AUTHORIZED)

        (asserts! (or
            (>= stacks-block-time (get expires-at escrow))  ;; Clarity 4
            (is-eq tx-sender (get buyer escrow))
        ) ERR-NOT-AUTHORIZED)

        (map-set purchase-escrows
            { escrow-id: escrow-id }
            (merge escrow { refunded: true })
        )

        (ok true)
    )
)

(define-public (purchase-listing-direct (listing-id uint) (access-level uint) (tx-id (buff 32)))
    (let (
        (listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR-LISTING-NOT-FOUND))
        (owner (get owner listing))
    )
        (let ((eligibility-result (verify-purchase-eligibility listing-id access-level)))
            (asserts! (is-ok eligibility-result) ERR-NO-VALID-CONSENT)
        )

        (let ((price (unwrap! (get-access-level-price listing-id access-level) ERR-INVALID-PRICE)))
            (asserts! (>= (stx-get-balance tx-sender) price) ERR-INSUFFICIENT-BALANCE)

            (let (
                (fee-percent (get platform-fee-percent listing))
                (fee-amount (/ (* price fee-percent) u10000))
                (seller-amount (- price fee-amount))
            )
                (map-set user-purchases
                    { user: tx-sender, listing-id: listing-id }
                    {
                        purchase-time: stacks-block-time,              ;; Clarity 4: Unix timestamp
                        access-expiry: (+ stacks-block-time u2592000), ;; Clarity 4: ~30 days in seconds
                        access-level: access-level,
                        transaction-id: tx-id,
                        purchase-price: price
                    }
                )

                (let ((log-result (contract-call? .compliance log-data-access
                    (get data-id listing)
                    u1
                    tx-id
                )))
                    (asserts! (is-ok log-result) ERR-PAYMENT-FAILED)
                )

                (let ((access-result (contract-call? .genetic-data grant-access
                    (get data-id listing)
                    tx-sender
                    access-level
                )))
                    (asserts! (is-ok access-result) ERR-PAYMENT-FAILED)
                )

                (ok true)
            )
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
        purchase-data (ok (< stacks-block-time (get access-expiry purchase-data)))  ;; Clarity 4
        (err u404)
    )
)

(define-public (grant-access (data-id uint) (user principal) (access-level uint))
    (begin
        (asserts! (is-eq tx-sender (var-get marketplace-admin)) ERR-NOT-AUTHORIZED)
        (map-set user-purchases
            { user: user, listing-id: data-id }
            {
                purchase-time: stacks-block-time,              ;; Clarity 4: Unix timestamp
                access-expiry: (+ stacks-block-time u2592000), ;; Clarity 4: ~30 days in seconds
                access-level: access-level,
                transaction-id: 0x00,
                purchase-price: u0
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

(define-read-only (get-escrow (escrow-id uint))
    (map-get? purchase-escrows { escrow-id: escrow-id })
)

(define-public (extend-access (listing-id uint) (user principal) (duration uint))
    (let (
        (listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR-LISTING-NOT-FOUND))
        (purchase (unwrap! (map-get? user-purchases { user: user, listing-id: listing-id }) ERR-NOT-FOUND))
    )
        (asserts! (or
            (is-eq tx-sender (get owner listing))
            (is-eq tx-sender (var-get marketplace-admin))
        ) ERR-NOT-AUTHORIZED)

        (map-set user-purchases
            { user: user, listing-id: listing-id }
            (merge purchase {
                access-expiry: (+ (get access-expiry purchase) duration)
            })
        )

        (ok true)
    )
)
