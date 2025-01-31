;; genetic-data.clar - Core contract for genetic data management

(define-data-var admin principal tx-sender)

;; Data structures
(define-map genetic-data-entries
    { data-id: uint }
    {
        owner: principal,
        price: uint,
        access-level: uint,
        metadata-hash: (string-utf8 64),
        encrypted-storage-url: (string-utf8 256)
    }
)

(define-map data-access-rights
    { data-id: uint, user: principal }
    { 
        access-level: uint,
        expiration: uint
    }
)

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-DATA (err u101))
(define-constant ERR-PAYMENT-FAILED (err u102))

;; Data submission
(define-public (submit-genetic-data 
    (data-id uint) 
    (price uint)
    (access-level uint)
    (metadata-hash (string-utf8 64))
    (encrypted-url (string-utf8 256)))
    (begin
        (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
        (map-set genetic-data-entries
            { data-id: data-id }
            {
                owner: tx-sender,
                price: price,
                access-level: access-level,
                metadata-hash: metadata-hash,
                encrypted-storage-url: encrypted-url
            }
        )
        (ok true)
    )
)

;; Purchase access
(define-public (purchase-access (data-id uint) (requested-level uint))
    (let (
        (data (unwrap! (map-get? genetic-data-entries { data-id: data-id }) ERR-INVALID-DATA))
        (price (* (get price data) requested-level))
    )
        (asserts! (>= (stx-get-balance tx-sender) price) ERR-PAYMENT-FAILED)
        (try! (stx-transfer? price tx-sender (get owner data)))
        (map-set data-access-rights
            { data-id: data-id, user: tx-sender }
            {
                access-level: requested-level,
                expiration: (+ block-height u8640) ;; Access expires after ~30 days
            }
        )
        (ok true)
    )
)

;; Check access rights
(define-read-only (check-access-rights (data-id uint) (user principal))
    (match (map-get? data-access-rights { data-id: data-id, user: user })
        access-data (ok access-data)
        ERR-NOT-AUTHORIZED
    )
)
