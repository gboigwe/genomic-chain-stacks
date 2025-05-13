;; title: verification
;; version: 1.0.1
;; summary: Handles verification of zero-knowledge proofs for genetic data
;; description:Enables verification of data properties without revealing the actual data

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PROOF (err u101))
(define-constant ERR-VERIFICATION-FAILED (err u102))
(define-constant ERR-PROOF-NOT-FOUND (err u103))
(define-constant ERR-INVALID-DATA (err u104))
(define-constant ERR-ALREADY-EXISTS (err u105))
(define-constant ERR-NOT-FOUND (err u106))
(define-constant ERR-VERIFIER-INACTIVE (err u107))

;; Constants
(define-constant PROOF-TYPE-GENE-PRESENCE u1)  ;; Proof that a specific gene exists
(define-constant PROOF-TYPE-GENE-ABSENCE u2)   ;; Proof that a specific gene does not exist
(define-constant PROOF-TYPE-GENE-VARIANT u3)   ;; Proof of a specific gene variant
(define-constant PROOF-TYPE-AGGREGATE u4)      ;; Proof of aggregate statistics

;; Data structures

;; Store registered proof verifiers (trusted external verifiers)
(define-map proof-verifiers
    { verifier-id: uint }
    {
        address: principal,
        name: (string-utf8 64),
        active: bool,
        verification-count: uint,
        added-at: uint
    }
)

;; Store proof metadata for genetic data
(define-map proof-registry
    { proof-id: uint }
    {
        data-id: uint,              ;; Reference to the genetic data
        proof-type: uint,           ;; Type of proof (presence, absence, etc.)
        proof-hash: (buff 32),      ;; Hash of the actual ZK proof
        parameters: (buff 256),     ;; Parameters for the proof verification
        creator: principal,         ;; Who created this proof
        verified: bool,             ;; Has this been verified?
        verifier: (optional uint),  ;; Which verifier validated this
        created-at: uint            ;; When this proof was registered
    }
)

;; Track verification results
(define-map verification-results
    { proof-id: uint }
    {
        result: bool,               ;; True if verified successfully
        verifier: uint,             ;; Which verifier performed this verification
        verified-at: uint,          ;; When this verification occurred
        verification-tx: (buff 32)  ;; Transaction ID of the verification
    }
)

;; Counters
(define-data-var next-verifier-id uint u1)
(define-data-var next-proof-id uint u1)

;; Administrative functions
(define-data-var contract-owner principal tx-sender)

;; Register a new proof verifier
(define-public (register-verifier (name (string-utf8 64)) (verifier-address principal))
    (begin
        ;; Only contract owner can register verifiers
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        
        (let ((verifier-id (var-get next-verifier-id)))
            ;; Update the counter for next verifier
            (var-set next-verifier-id (+ verifier-id u1))
            
            ;; Add verifier to the registry
            (map-set proof-verifiers
                { verifier-id: verifier-id }
                {
                    address: verifier-address,
                    name: name,
                    active: true,
                    verification-count: u0,
                    added-at: stacks-block-height
                }
            )
            
            (ok verifier-id)
        )
    )
)

;; Deactivate a verifier
(define-public (deactivate-verifier (verifier-id uint))
    (begin
        ;; Only contract owner can deactivate verifiers
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
    
    (let ((proof-id (var-get next-proof-id)))
        ;; Update the counter for next proof
        (var-set next-proof-id (+ proof-id u1))
        
        ;; Register the proof
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
                created-at: stacks-block-height
            }
        )
        
        (ok proof-id)
    )
)

;; Verify a zero-knowledge proof
(define-public (verify-proof (proof-id uint) (verifier-id uint) (verification-tx (buff 32)))
    (begin
        ;; Get proof and verifier
        (let (
            (proof (unwrap! (map-get? proof-registry { proof-id: proof-id }) ERR-PROOF-NOT-FOUND))
            (verifier (unwrap! (map-get? proof-verifiers { verifier-id: verifier-id }) ERR-NOT-FOUND))
        )
            ;; Check verifier is active
            (asserts! (get active verifier) ERR-VERIFIER-INACTIVE)
            
            ;; Check verifier is authorized to verify this proof
            (asserts! (is-eq tx-sender (get address verifier)) ERR-NOT-AUTHORIZED)
            
            ;; Update verification count for verifier
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
            
            ;; Record verification result (always true for successful verifications)
            (map-set verification-results
                { proof-id: proof-id }
                {
                    result: true,
                    verifier: verifier-id,
                    verified-at: stacks-block-height,
                    verification-tx: verification-tx
                }
            )
            
            ;; Update proof to show it's been verified
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

;; Set contract owner
(define-public (set-contract-owner (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (ok (var-set contract-owner new-owner))
    )
)
