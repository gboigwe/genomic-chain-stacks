
;; title: compliance
;; version: 1.0.2
;; summary: Manages compliance with healthcare regulations for genetic data
;; description: Tracks consent, usage, and provides audit trail for genetic data

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-DATA (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-EXPIRED (err u104))
(define-constant ERR-NO-CONSENT (err u105))

;; Constants for jurisdiction
(define-constant JURISDICTION-GLOBAL u0)
(define-constant JURISDICTION-US u1)    ;; United States (HIPAA)
(define-constant JURISDICTION-EU u2)    ;; European Union (GDPR)
(define-constant JURISDICTION-UK u3)    ;; United Kingdom 
(define-constant JURISDICTION-CANADA u4) ;; Canada

;; Constants for consent types
(define-constant CONSENT-RESEARCH u1)    ;; General research use
(define-constant CONSENT-COMMERCIAL u2)  ;; Commercial use
(define-constant CONSENT-CLINICAL u3)    ;; Clinical use

;; Data structures

;; Consent records - tracks consent given by users for their genetic data
(define-map consent-records
    { data-id: uint }
    {
        owner: principal,                ;; Owner of the genetic data
        research-consent: bool,          ;; Research use consent
        commercial-consent: bool,        ;; Commercial use consent
        clinical-consent: bool,          ;; Clinical use consent
        jurisdiction: uint,              ;; Legal jurisdiction for this data
        consent-expires-at: uint,        ;; When consent expires
        last-updated: uint               ;; When consent was last updated
    }
)

;; Data usage records - tracks how data is being used
(define-map usage-records
    { usage-id: uint }
    {
        data-id: uint,                   ;; Reference to the genetic data
        user: principal,                 ;; Who is using the data
        purpose: uint,                   ;; Purpose of use (research, commercial, etc.)
        access-granted-at: uint,         ;; When access was granted
        access-expires-at: uint,         ;; When access expires
        access-level: uint               ;; Level of access granted
    }
)

;; Access logs - audit trail of data access
(define-map access-logs
    { log-id: uint }
    {
        data-id: uint,                   ;; Reference to the genetic data
        user: principal,                 ;; Who accessed the data
        timestamp: uint,                 ;; When access occurred
        purpose: uint,                   ;; Purpose of access
        tx-id: (buff 32)                 ;; Transaction ID for this access
    }
)

;; Counters
(define-data-var next-usage-id uint u1)
(define-data-var next-log-id uint u1)

;; Register consent for genetic data
(define-public (register-consent
    (data-id uint)
    (research-consent bool)
    (commercial-consent bool)
    (clinical-consent bool)
    (jurisdiction uint)
    (consent-duration uint))  ;; Duration in blocks
    
    (begin
        (let (
            (current-time stacks-block-height)
            (expiration-time (+ stacks-block-height consent-duration))
        )
            ;; Set the consent record
            (map-set consent-records
                { data-id: data-id }
                {
                    owner: tx-sender,
                    research-consent: research-consent,
                    commercial-consent: commercial-consent,
                    clinical-consent: clinical-consent,
                    jurisdiction: jurisdiction,
                    consent-expires-at: expiration-time,
                    last-updated: current-time
                }
            )
            
            (ok true)
        )
    )
)

;; Update existing consent
(define-public (update-consent
    (data-id uint)
    (research-consent bool)
    (commercial-consent bool)
    (clinical-consent bool)
    (jurisdiction uint)
    (consent-duration uint))  ;; Duration in blocks
    
    (let ((consent (unwrap! (map-get? consent-records { data-id: data-id }) ERR-NOT-FOUND)))
        ;; Only the owner can update consent
        (asserts! (is-eq tx-sender (get owner consent)) ERR-NOT-AUTHORIZED)
        
        (let (
            (current-time stacks-block-height)
            (expiration-time (+ stacks-block-height consent-duration))
        )
            ;; Update the consent record
            (map-set consent-records
                { data-id: data-id }
                {
                    owner: tx-sender,
                    research-consent: research-consent,
                    commercial-consent: commercial-consent,
                    clinical-consent: clinical-consent,
                    jurisdiction: jurisdiction,
                    consent-expires-at: expiration-time,
                    last-updated: current-time
                }
            )
            
            (ok true)
        )
    )
)

;; Register a new data usage
(define-public (register-data-usage
    (data-id uint)
    (user principal)
    (purpose uint)
    (access-duration uint)  ;; Duration in blocks
    (access-level uint))
    
    (let (
        (consent (unwrap! (map-get? consent-records { data-id: data-id }) ERR-NOT-FOUND))
        (usage-id (var-get next-usage-id))
        (current-time stacks-block-height)
    )
        ;; Verify consent is valid and not expired
        (asserts! (< current-time (get consent-expires-at consent)) ERR-EXPIRED)
        
        ;; Verify consent for the specific purpose
        (asserts! 
            (or 
                (and (is-eq purpose CONSENT-RESEARCH) (get research-consent consent))
                (and (is-eq purpose CONSENT-COMMERCIAL) (get commercial-consent consent))
                (and (is-eq purpose CONSENT-CLINICAL) (get clinical-consent consent))
            )
            ERR-NO-CONSENT
        )
        
        ;; Increment the usage ID counter
        (var-set next-usage-id (+ usage-id u1))
        
        ;; Register the usage
        (map-set usage-records
            { usage-id: usage-id }
            {
                data-id: data-id,
                user: user,
                purpose: purpose,
                access-granted-at: current-time,
                access-expires-at: (+ current-time access-duration),
                access-level: access-level
            }
        )
        
        (ok usage-id)
    )
)

;; Administrative functions
(define-data-var contract-owner principal tx-sender)

;; Set contract owner
(define-public (set-contract-owner (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (ok (var-set contract-owner new-owner))
    )
)
