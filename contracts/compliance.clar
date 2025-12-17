;; title: compliance
;; version: 2.0.0 - Clarity 4
;; summary: Manages compliance with healthcare regulations for genetic data
;; description: Tracks consent, usage, and provides audit trail for genetic data

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-DATA (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-EXPIRED (err u104))
(define-constant ERR-NO-CONSENT (err u105))
(define-constant ERR-INVALID-JURISDICTION (err u106))
(define-constant ERR-INVALID-PURPOSE (err u107))
(define-constant ERR-GDPR-RECORD-MISSING (err u108))

;; Constants for jurisdiction
(define-constant JURISDICTION-GLOBAL u0)
(define-constant JURISDICTION-US u1)
(define-constant JURISDICTION-EU u2)
(define-constant JURISDICTION-UK u3)
(define-constant JURISDICTION-CANADA u4)

;; Constants for consent types
(define-constant CONSENT-RESEARCH u1)
(define-constant CONSENT-COMMERCIAL u2)
(define-constant CONSENT-CLINICAL u3)

;; Consent records
(define-map consent-records
    { data-id: uint }
    {
        owner: principal,
        research-consent: bool,
        commercial-consent: bool,
        clinical-consent: bool,
        jurisdiction: uint,
        consent-expires-at: uint,          ;; Clarity 4: Unix timestamp
        last-updated: uint                 ;; Clarity 4: Unix timestamp
    }
)

;; Data usage records
(define-map usage-records
    { usage-id: uint }
    {
        data-id: uint,
        user: principal,
        purpose: uint,
        access-granted-at: uint,           ;; Clarity 4: Unix timestamp
        access-expires-at: uint,           ;; Clarity 4: Unix timestamp
        access-level: uint
    }
)

;; Access logs - audit trail
(define-map access-logs
    { log-id: uint }
    {
        data-id: uint,
        user: principal,
        timestamp: uint,                   ;; Clarity 4: Unix timestamp
        purpose: uint,
        tx-id: (buff 32)
    }
)

;; GDPR Specific Requirements
(define-map gdpr-records
    { data-id: uint }
    {
        right-to-be-forgotten-requested: bool,
        data-portability-requested: bool,
        processing-restricted: bool,
        last-updated: uint                 ;; Clarity 4: Unix timestamp
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
    (consent-duration uint))  ;; Duration in seconds

    (begin
        (asserts! (or
            (is-eq jurisdiction JURISDICTION-GLOBAL)
            (is-eq jurisdiction JURISDICTION-US)
            (is-eq jurisdiction JURISDICTION-EU)
            (is-eq jurisdiction JURISDICTION-UK)
            (is-eq jurisdiction JURISDICTION-CANADA)
        ) ERR-INVALID-JURISDICTION)

        (let (
            (current-time stacks-block-time)                   ;; Clarity 4: Unix timestamp
            (expiration-time (+ stacks-block-time consent-duration))  ;; Clarity 4
        )
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

            (if (is-eq jurisdiction JURISDICTION-EU)
                (map-set gdpr-records
                    { data-id: data-id }
                    {
                        right-to-be-forgotten-requested: false,
                        data-portability-requested: false,
                        processing-restricted: false,
                        last-updated: current-time
                    }
                )
                true
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
    (consent-duration uint))  ;; Duration in seconds

    (let ((consent (unwrap! (map-get? consent-records { data-id: data-id }) ERR-NOT-FOUND)))
        (asserts! (is-eq tx-sender (get owner consent)) ERR-NOT-AUTHORIZED)

        (asserts! (or
            (is-eq jurisdiction JURISDICTION-GLOBAL)
            (is-eq jurisdiction JURISDICTION-US)
            (is-eq jurisdiction JURISDICTION-EU)
            (is-eq jurisdiction JURISDICTION-UK)
            (is-eq jurisdiction JURISDICTION-CANADA)
        ) ERR-INVALID-JURISDICTION)

        (let (
            (current-time stacks-block-time)                    ;; Clarity 4: Unix timestamp
            (expiration-time (+ stacks-block-time consent-duration))   ;; Clarity 4
        )
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

            (if (and (is-eq jurisdiction JURISDICTION-EU) (is-none (map-get? gdpr-records { data-id: data-id })))
                (map-set gdpr-records
                    { data-id: data-id }
                    {
                        right-to-be-forgotten-requested: false,
                        data-portability-requested: false,
                        processing-restricted: false,
                        last-updated: current-time
                    }
                )
                true
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
    (access-duration uint)  ;; Duration in seconds
    (access-level uint))

    (let (
        (consent (unwrap! (map-get? consent-records { data-id: data-id }) ERR-NOT-FOUND))
        (usage-id (var-get next-usage-id))
        (current-time stacks-block-time)   ;; Clarity 4: Unix timestamp
    )
        (asserts! (< current-time (get consent-expires-at consent)) ERR-EXPIRED)

        (asserts! (or
            (is-eq purpose CONSENT-RESEARCH)
            (is-eq purpose CONSENT-COMMERCIAL)
            (is-eq purpose CONSENT-CLINICAL)
        ) ERR-INVALID-PURPOSE)

        (asserts!
            (or
                (and (is-eq purpose CONSENT-RESEARCH) (get research-consent consent))
                (and (is-eq purpose CONSENT-COMMERCIAL) (get commercial-consent consent))
                (and (is-eq purpose CONSENT-CLINICAL) (get clinical-consent consent))
            )
            ERR-NO-CONSENT
        )

        (if (is-eq (get jurisdiction consent) JURISDICTION-EU)
            (let ((gdpr-data (map-get? gdpr-records { data-id: data-id })))
                (if (is-some gdpr-data)
                    (asserts! (not (get processing-restricted (unwrap! gdpr-data ERR-GDPR-RECORD-MISSING))) ERR-NOT-AUTHORIZED)
                    true
                )
            )
            true
        )

        (var-set next-usage-id (+ usage-id u1))

        (map-set usage-records
            { usage-id: usage-id }
            {
                data-id: data-id,
                user: user,
                purpose: purpose,
                access-granted-at: current-time,
                access-expires-at: (+ current-time access-duration),   ;; Clarity 4
                access-level: access-level
            }
        )

        (ok usage-id)
    )
)

;; Log data access (creates audit trail)
(define-public (log-data-access
    (data-id uint)
    (purpose uint)
    (tx-id (buff 32)))

    (let (
        (log-id (var-get next-log-id))
        (current-time stacks-block-time)   ;; Clarity 4: Unix timestamp
    )
        (var-set next-log-id (+ log-id u1))

        (map-set access-logs
            { log-id: log-id }
            {
                data-id: data-id,
                user: tx-sender,
                timestamp: current-time,
                purpose: purpose,
                tx-id: tx-id
            }
        )

        (ok log-id)
    )
)

;; Check if consent is valid for a specific purpose
(define-public (check-consent-validity
    (data-id uint)
    (purpose uint))

    (match (map-get? consent-records { data-id: data-id })
        consent
        (let (
            (current-time stacks-block-time)                ;; Clarity 4: Unix timestamp
            (is-expired (>= current-time (get consent-expires-at consent)))
            (has-purpose-consent
                (or
                    (and (is-eq purpose CONSENT-RESEARCH) (get research-consent consent))
                    (and (is-eq purpose CONSENT-COMMERCIAL) (get commercial-consent consent))
                    (and (is-eq purpose CONSENT-CLINICAL) (get clinical-consent consent))
                )
            )
        )
            (ok (and (not is-expired) has-purpose-consent))
        )
        (err ERR-NOT-FOUND)
    )
)

;; GDPR Specific Functions

;; Request right to be forgotten (GDPR)
(define-public (request-right-to-be-forgotten (data-id uint))
    (let (
        (consent (unwrap! (map-get? consent-records { data-id: data-id }) ERR-NOT-FOUND))
        (current-time stacks-block-time)   ;; Clarity 4: Unix timestamp
    )
        (asserts! (is-eq tx-sender (get owner consent)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get jurisdiction consent) JURISDICTION-EU) ERR-INVALID-JURISDICTION)

        (let ((gdpr-record (unwrap! (map-get? gdpr-records { data-id: data-id }) ERR-GDPR-RECORD-MISSING)))
            (map-set gdpr-records
                { data-id: data-id }
                {
                    right-to-be-forgotten-requested: true,
                    data-portability-requested: (get data-portability-requested gdpr-record),
                    processing-restricted: (get processing-restricted gdpr-record),
                    last-updated: current-time
                }
            )

            (ok true)
        )
    )
)

;; Request data portability (GDPR)
(define-public (request-data-portability (data-id uint))
    (let (
        (consent (unwrap! (map-get? consent-records { data-id: data-id }) ERR-NOT-FOUND))
        (current-time stacks-block-time)   ;; Clarity 4: Unix timestamp
    )
        (asserts! (is-eq tx-sender (get owner consent)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get jurisdiction consent) JURISDICTION-EU) ERR-INVALID-JURISDICTION)

        (let ((gdpr-record (unwrap! (map-get? gdpr-records { data-id: data-id }) ERR-GDPR-RECORD-MISSING)))
            (map-set gdpr-records
                { data-id: data-id }
                {
                    right-to-be-forgotten-requested: (get right-to-be-forgotten-requested gdpr-record),
                    data-portability-requested: true,
                    processing-restricted: (get processing-restricted gdpr-record),
                    last-updated: current-time
                }
            )

            (ok true)
        )
    )
)

;; Restrict data processing (GDPR)
(define-public (restrict-data-processing (data-id uint))
    (let (
        (consent (unwrap! (map-get? consent-records { data-id: data-id }) ERR-NOT-FOUND))
        (current-time stacks-block-time)   ;; Clarity 4: Unix timestamp
    )
        (asserts! (is-eq tx-sender (get owner consent)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get jurisdiction consent) JURISDICTION-EU) ERR-INVALID-JURISDICTION)

        (let ((gdpr-record (unwrap! (map-get? gdpr-records { data-id: data-id }) ERR-GDPR-RECORD-MISSING)))
            (map-set gdpr-records
                { data-id: data-id }
                {
                    right-to-be-forgotten-requested: (get right-to-be-forgotten-requested gdpr-record),
                    data-portability-requested: (get data-portability-requested gdpr-record),
                    processing-restricted: true,
                    last-updated: current-time
                }
            )

            (ok true)
        )
    )
)

;; Restore data processing (GDPR)
(define-public (restore-data-processing (data-id uint))
    (let (
        (consent (unwrap! (map-get? consent-records { data-id: data-id }) ERR-NOT-FOUND))
        (current-time stacks-block-time)   ;; Clarity 4: Unix timestamp
    )
        (asserts! (is-eq tx-sender (get owner consent)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get jurisdiction consent) JURISDICTION-EU) ERR-INVALID-JURISDICTION)

        (let ((gdpr-record (unwrap! (map-get? gdpr-records { data-id: data-id }) ERR-GDPR-RECORD-MISSING)))
            (map-set gdpr-records
                { data-id: data-id }
                {
                    right-to-be-forgotten-requested: (get right-to-be-forgotten-requested gdpr-record),
                    data-portability-requested: (get data-portability-requested gdpr-record),
                    processing-restricted: false,
                    last-updated: current-time
                }
            )

            (ok true)
        )
    )
)

;; Read functions
(define-read-only (get-consent (data-id uint))
    (map-get? consent-records { data-id: data-id })
)

(define-read-only (get-usage (usage-id uint))
    (map-get? usage-records { usage-id: usage-id })
)

(define-read-only (get-access-log (log-id uint))
    (map-get? access-logs { log-id: log-id })
)

(define-read-only (get-gdpr-record (data-id uint))
    (map-get? gdpr-records { data-id: data-id })
)

;; Administrative functions
(define-data-var contract-owner principal tx-sender)

(define-public (set-contract-owner (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (ok (var-set contract-owner new-owner))
    )
)
