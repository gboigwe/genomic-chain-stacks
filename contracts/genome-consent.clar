;; genome-consent.clar - Clarity 4
;; Patient consent tracking for genomic data

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CONSENT-EXISTS (err u101))
(define-constant ERR-CONSENT-NOT-FOUND (err u102))

(define-map consent-records
  { patient: principal, data-type: (string-ascii 50) }
  {
    granted: bool,
    granted-at: uint,
    expires-at: uint,
    scope: (string-ascii 100),
    revocable: bool,
    purpose: (string-ascii 100)
  }
)

(define-map consent-history
  { patient: principal, timestamp: uint }
  {
    action: (string-ascii 20),
    data-type: (string-ascii 50),
    recorded-at: uint
  }
)

(define-public (grant-consent
    (data-type (string-ascii 50))
    (expiration uint)
    (scope (string-ascii 100))
    (purpose (string-ascii 100)))
  (begin
    (map-set consent-records { patient: tx-sender, data-type: data-type }
      {
        granted: true,
        granted-at: stacks-block-time,
        expires-at: expiration,
        scope: scope,
        revocable: true,
        purpose: purpose
      })
    (map-set consent-history { patient: tx-sender, timestamp: stacks-block-time }
      {
        action: "granted",
        data-type: data-type,
        recorded-at: stacks-block-time
      })
    (ok true)))

(define-public (revoke-consent (data-type (string-ascii 50)))
  (begin
    (asserts! (is-some (map-get? consent-records { patient: tx-sender, data-type: data-type })) ERR-CONSENT-NOT-FOUND)
    (map-delete consent-records { patient: tx-sender, data-type: data-type })
    (map-set consent-history { patient: tx-sender, timestamp: stacks-block-time }
      {
        action: "revoked",
        data-type: data-type,
        recorded-at: stacks-block-time
      })
    (ok true)))

;; Clarity 4: principal-destruct? - Validate patient
(define-read-only (validate-patient (patient principal))
  (principal-destruct? patient))

;; Clarity 4: int-to-utf8 - Format timestamp
(define-read-only (format-timestamp (timestamp uint))
  (ok (int-to-utf8 timestamp)))

;; Clarity 4: stacks-block-time
(define-read-only (get-current-time)
  (ok stacks-block-time))

(define-read-only (get-consent (patient principal) (data-type (string-ascii 50)))
  (ok (map-get? consent-records { patient: patient, data-type: data-type })))

(define-read-only (is-consent-valid (patient principal) (data-type (string-ascii 50)))
  (match (map-get? consent-records { patient: patient, data-type: data-type })
    consent (ok (and (get granted consent) (< stacks-block-time (get expires-at consent))))
    (ok false)))
