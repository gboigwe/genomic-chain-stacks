
;; title: genetic-data
;; version: 1.0.1
;; summary: Core contract for genetic data management on the Stacks blockchain
;; description: This contract handles data ownership, access control, and metadata management

;; Import trait 
(impl-trait .genetic-data-trait.genetic-data-trait)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-DATA (err u101))
(define-constant ERR-DATA-EXISTS (err u102))
(define-constant ERR-DATA-NOT-FOUND (err u103))
(define-constant ERR-INVALID-ACCESS-LEVEL (err u104))

;; Data structures
(define-map genetic-datasets
    { data-id: uint }
    {
        owner: principal,
        price: uint,
        access-level: uint,
        metadata-hash: (buff 32),          ;; Hash of genetic data metadata
        encrypted-storage-url: (string-utf8 256),  ;; IPFS or other storage URL
        description: (string-utf8 256),     ;; Brief description of the dataset
        created-at: uint,                  ;; Block height when created
        updated-at: uint                   ;; Block height when last updated
    }
)

;; Track access rights for each data set
(define-map access-rights
    { data-id: uint, user: principal }
    {
        access-level: uint,                ;; 1=basic, 2=detailed, 3=full
        expiration: uint,                  ;; Block height when access expires
        granted-by: principal              ;; Who granted the access
    }
)

;; Administrative functions
(define-data-var contract-owner principal tx-sender)

;; Register a new genetic dataset
(define-public (register-genetic-data
    (data-id uint)
    (price uint)
    (access-level uint)
    (metadata-hash (buff 32))
    (storage-url (string-utf8 256))
    (description (string-utf8 256)))
    
    (let ((existing-data (map-get? genetic-datasets { data-id: data-id })))
        (asserts! (is-none existing-data) ERR-DATA-EXISTS)
        (asserts! (> access-level u0) ERR-INVALID-ACCESS-LEVEL)
        (asserts! (<= access-level u3) ERR-INVALID-ACCESS-LEVEL)
        
        (map-set genetic-datasets
            { data-id: data-id }
            {
                owner: tx-sender,
                price: price,
                access-level: access-level,
                metadata-hash: metadata-hash,
                encrypted-storage-url: storage-url,
                description: description,
                created-at: stacks-block-height,
                updated-at: stacks-block-height
            }
        )
        (ok true)
    )
)

;; Implement trait functions

;; Get data details - implements trait function
(define-public (get-data-details (data-id uint))
    (match (map-get? genetic-datasets { data-id: data-id })
        dataset (ok {
            owner: (get owner dataset),
            price: (get price dataset),
            access-level: (get access-level dataset),
            metadata-hash: (get metadata-hash dataset)
        })
        (err u404)
    )
)

;; Verify access rights - implements trait function
(define-public (verify-access-rights (data-id uint) (user principal))
    (match (map-get? access-rights { data-id: data-id, user: user })
        rights (ok (< stacks-block-height (get expiration rights)))
        (err u404)
    )
)

;; Grant access - implements trait function
(define-public (grant-access (data-id uint) (user principal) (access-level uint))
    (let ((dataset (unwrap! (map-get? genetic-datasets { data-id: data-id }) ERR-DATA-NOT-FOUND)))
        ;; Only the owner can grant access
        (asserts! (is-eq (get owner dataset) tx-sender) ERR-NOT-AUTHORIZED)
        
        ;; Ensure access level is valid
        (asserts! (> access-level u0) ERR-INVALID-ACCESS-LEVEL)
        (asserts! (<= access-level (get access-level dataset)) ERR-INVALID-ACCESS-LEVEL)
        
        (map-set access-rights
            { data-id: data-id, user: user }
            {
                access-level: access-level,
                expiration: (+ stacks-block-height u8640), ;; Access expires after ~30 days
                granted-by: tx-sender
            }
        )
        (ok true)
    )
)
