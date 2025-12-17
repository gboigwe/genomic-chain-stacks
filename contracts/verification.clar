;; title: verification
;; version: 2.0.0 - Clarity 4
;; summary: Handles verification of zero-knowledge proofs for genetic data
;; description: Enables verification of data properties without revealing the actual data

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PROOF (err u101))
(define-constant ERR-VERIFICATION-FAILED (err u102))
(define-constant ERR-PROOF-NOT-FOUND (err u103))
(define-constant ERR-INVALID-DATA (err u104))
(define-constant ERR-ALREADY-EXISTS (err u105))
(define-constant ERR-NOT-FOUND (err u106))
(define-constant ERR-VERIFIER-INACTIVE (err u107))
(define-constant ERR-INVALID-PROOF-TYPE (err u108))

;; Constants for proof types
(define-constant PROOF-TYPE-GENE-PRESENCE u1)
(define-constant PROOF-TYPE-GENE-ABSENCE u2)
(define-constant PROOF-TYPE-GENE-VARIANT u3)
(define-constant PROOF-TYPE-AGGREGATE u4)

;; Store registered proof verifiers
(define-map proof-verifiers
    { verifier-id: uint }
    {
        address: principal,
        name: (string-utf8 64),
        active: bool,
        verification-count: uint,
        added-at: uint                    ;; Clarity 4: Unix timestamp
    }
)

;; Store proof metadata
(define-map proof-registry
    { proof-id: uint }
    {
        data-id: uint,
        proof-type: uint,
        proof-hash: (buff 32),
        parameters: (buff 256),
        creator: principal,
        verified: bool,
        verifier: (optional uint),
        created-at: uint                  ;; Clarity 4: Unix timestamp
    }
)

;; Track verification results
(define-map verification-results
    { proof-id: uint }
    {
        result: bool,
        verifier: uint,
        verified-at: uint,                ;; Clarity 4: Unix timestamp
        verification-tx: (buff 32)
    }
)

;; Map data IDs to their proofs
(define-map data-proofs
    { data-id: uint, proof-type: uint }
    { proof-ids: (list 10 uint) }
)

;; Counters
(define-data-var next-verifier-id uint u1)
(define-data-var next-proof-id uint u1)
(define-data-var contract-owner principal tx-sender)

;; Register a new proof verifier
(define-public (register-verifier (name (string-utf8 64)) (verifier-address principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)

        (let ((verifier-id (var-get next-verifier-id)))
            (var-set next-verifier-id (+ verifier-id u1))

            (map-set proof-verifiers
                { verifier-id: verifier-id }
                {
                    address: verifier-address,
                    name: name,
                    active: true,
                    verification-count: u0,
                    added-at: stacks-block-time    ;; Clarity 4: Unix timestamp
                }
            )

            (ok verifier-id)
        )
    )
)

;; Deactivate a verifier
(define-public (deactivate-verifier (verifier-id uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)

        (let ((verifier (unwrap! (map-get? proof-verifiers { verifier-id: verifier-id }) ERR-NOT-FOUND)))
            (map-set proof-verifiers
                { verifier-id: verifier-id }
                {
                    address: (get address verifier),
                    name: (get name verifier),
                    active: false,
                    verification-count: (get verification-count verifier),
                    added-at: (get added-at verifier)
                }
            )

            (ok true)
        )
    )
)

;; Register a new zero-knowledge proof
(define-public (register-proof
    (data-id uint)
    (proof-type uint)
    (proof-hash (buff 32))
    (parameters (buff 256)))

    (begin
        (asserts! (or
            (is-eq proof-type PROOF-TYPE-GENE-PRESENCE)
            (is-eq proof-type PROOF-TYPE-GENE-ABSENCE)
            (is-eq proof-type PROOF-TYPE-GENE-VARIANT)
            (is-eq proof-type PROOF-TYPE-AGGREGATE)
        ) ERR-INVALID-PROOF-TYPE)

        (let ((proof-id (var-get next-proof-id)))
            (var-set next-proof-id (+ proof-id u1))

            (map-set proof-registry
                { proof-id: proof-id }
                {
                    data-id: data-id,
                    proof-type: proof-type,
                    proof-hash: proof-hash,
                    parameters: parameters,
                    creator: tx-sender,
                    verified: false,
                    verifier: none,
                    created-at: stacks-block-time  ;; Clarity 4: Unix timestamp
                }
            )

            (match (map-get? data-proofs { data-id: data-id, proof-type: proof-type })
                existing-proofs (map-set data-proofs
                    { data-id: data-id, proof-type: proof-type }
                    { proof-ids: (unwrap! (as-max-len? (append (get proof-ids existing-proofs) proof-id) u10) ERR-INVALID-DATA) }
                )
                (map-set data-proofs
                    { data-id: data-id, proof-type: proof-type }
                    { proof-ids: (list proof-id) }
                )
            )

            (ok proof-id)
        )
    )
)

;; Verify a zero-knowledge proof
(define-public (verify-proof (proof-id uint) (verifier-id uint) (verification-tx (buff 32)))
    (begin
        (let (
            (proof (unwrap! (map-get? proof-registry { proof-id: proof-id }) ERR-PROOF-NOT-FOUND))
            (verifier (unwrap! (map-get? proof-verifiers { verifier-id: verifier-id }) ERR-NOT-FOUND))
        )
            (asserts! (get active verifier) ERR-VERIFIER-INACTIVE)
            (asserts! (is-eq tx-sender (get address verifier)) ERR-NOT-AUTHORIZED)

            (map-set proof-verifiers
                { verifier-id: verifier-id }
                {
                    address: (get address verifier),
                    name: (get name verifier),
                    active: (get active verifier),
                    verification-count: (+ (get verification-count verifier) u1),
                    added-at: (get added-at verifier)
                }
            )

            (map-set verification-results
                { proof-id: proof-id }
                {
                    result: true,
                    verifier: verifier-id,
                    verified-at: stacks-block-time,  ;; Clarity 4: Unix timestamp
                    verification-tx: verification-tx
                }
            )

            (map-set proof-registry
                { proof-id: proof-id }
                {
                    data-id: (get data-id proof),
                    proof-type: (get proof-type proof),
                    proof-hash: (get proof-hash proof),
                    parameters: (get parameters proof),
                    creator: (get creator proof),
                    verified: true,
                    verifier: (some verifier-id),
                    created-at: (get created-at proof)
                }
            )

            (ok true)
        )
    )
)

;; Report a verification failure
(define-public (report-verification-failure (proof-id uint) (verifier-id uint) (verification-tx (buff 32)))
    (begin
        (let (
            (proof (unwrap! (map-get? proof-registry { proof-id: proof-id }) ERR-PROOF-NOT-FOUND))
            (verifier (unwrap! (map-get? proof-verifiers { verifier-id: verifier-id }) ERR-NOT-FOUND))
        )
            (asserts! (get active verifier) ERR-VERIFIER-INACTIVE)
            (asserts! (is-eq tx-sender (get address verifier)) ERR-NOT-AUTHORIZED)

            (map-set proof-verifiers
                { verifier-id: verifier-id }
                {
                    address: (get address verifier),
                    name: (get name verifier),
                    active: (get active verifier),
                    verification-count: (+ (get verification-count verifier) u1),
                    added-at: (get added-at verifier)
                }
            )

            (map-set verification-results
                { proof-id: proof-id }
                {
                    result: false,
                    verifier: verifier-id,
                    verified-at: stacks-block-time,  ;; Clarity 4: Unix timestamp
                    verification-tx: verification-tx
                }
            )

            (ok true)
        )
    )
)

;; Check if data has a verified proof of specified type
(define-public (check-verified-proof (data-id uint) (proof-type uint))
    (match (map-get? data-proofs { data-id: data-id, proof-type: proof-type })
        proof-list (filter-verified-proofs (get proof-ids proof-list))
        (ok (list))
    )
)

;; Helper function to filter verified proofs
(define-private (filter-verified-proofs (proof-ids (list 10 uint)))
    (ok (filter is-proof-verified proof-ids))
)

;; Helper function to check if a proof is verified
(define-private (is-proof-verified (proof-id uint))
    (match (map-get? proof-registry { proof-id: proof-id })
        proof (get verified proof)
        false
    )
)

;; Get proofs for a specific data ID and proof type
(define-read-only (get-proofs-by-data-id (data-id uint) (proof-type uint))
    (match (map-get? data-proofs { data-id: data-id, proof-type: proof-type })
        proof-list (ok (get proof-ids proof-list))
        (err ERR-NOT-FOUND)
    )
)

;; Get verifier details
(define-read-only (get-verifier (verifier-id uint))
    (map-get? proof-verifiers { verifier-id: verifier-id })
)

;; Get proof details
(define-read-only (get-proof (proof-id uint))
    (map-get? proof-registry { proof-id: proof-id })
)

;; Get verification result
(define-read-only (get-verification-result (proof-id uint))
    (map-get? verification-results { proof-id: proof-id })
)

;; Check if a proof has been verified
(define-read-only (is-verified (proof-id uint))
    (match (map-get? proof-registry { proof-id: proof-id })
        proof (get verified proof)
        false
    )
)

;; Set contract owner
(define-public (set-contract-owner (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (ok (var-set contract-owner new-owner))
    )
)
