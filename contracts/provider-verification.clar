;; provider-verification - Clarity 4
;; Comprehensive provider credential verification and validation system

(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-ALREADY-VERIFIED (err u102))
(define-constant ERR-EXPIRED (err u103))
(define-constant ERR-INVALID-VERIFIER (err u104))

(define-map verification-requests uint
  {
    provider: principal,
    credential-type: (string-ascii 50),
    credential-number: (string-ascii 100),
    requested-at: uint,
    status: (string-ascii 20),
    priority: (string-ascii 20)
  }
)

(define-map verification-results uint
  {
    request-id: uint,
    verifier: principal,
    is-valid: bool,
    verification-date: uint,
    expiry-date: uint,
    verification-proof: (buff 64),
    notes: (string-utf8 500)
  }
)

(define-map authorized-verifiers principal
  {
    verifier-name: (string-utf8 200),
    organization: (string-utf8 200),
    authorized-credentials: (list 10 (string-ascii 50)),
    total-verifications: uint,
    is-active: bool,
    authorized-at: uint
  }
)

(define-map verification-history { provider: principal, credential-type: (string-ascii 50) }
  {
    total-verifications: uint,
    last-verified: uint,
    current-status: (string-ascii 20),
    verification-count: uint
  }
)

(define-data-var request-counter uint u0)
(define-data-var result-counter uint u0)
(define-data-var verification-fee uint u100)

(define-public (submit-verification-request
    (credential-type (string-ascii 50))
    (credential-number (string-ascii 100))
    (priority (string-ascii 20)))
  (let ((request-id (+ (var-get request-counter) u1)))
    (map-set verification-requests request-id
      {
        provider: tx-sender,
        credential-type: credential-type,
        credential-number: credential-number,
        requested-at: stacks-block-time,
        status: "pending",
        priority: priority
      })
    (var-set request-counter request-id)
    (ok request-id)))

(define-public (process-verification
    (request-id uint)
    (is-valid bool)
    (expiry-date uint)
    (verification-proof (buff 64))
    (notes (string-utf8 500)))
  (let ((request (unwrap! (map-get? verification-requests request-id) ERR-NOT-FOUND))
        (verifier (unwrap! (map-get? authorized-verifiers tx-sender) ERR-INVALID-VERIFIER))
        (result-id (+ (var-get result-counter) u1)))
    (asserts! (get is-active verifier) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request) "pending") ERR-ALREADY-VERIFIED)
    (map-set verification-results result-id
      {
        request-id: request-id,
        verifier: tx-sender,
        is-valid: is-valid,
        verification-date: stacks-block-time,
        expiry-date: expiry-date,
        verification-proof: verification-proof,
        notes: notes
      })
    (map-set verification-requests request-id
      (merge request { status: (if is-valid "verified" "rejected") }))
    (update-verification-history (get provider request) (get credential-type request) is-valid)
    (var-set result-counter result-id)
    (ok result-id)))

(define-public (authorize-verifier
    (verifier principal)
    (verifier-name (string-utf8 200))
    (organization (string-utf8 200))
    (authorized-credentials (list 10 (string-ascii 50))))
  (ok (map-set authorized-verifiers verifier
    {
      verifier-name: verifier-name,
      organization: organization,
      authorized-credentials: authorized-credentials,
      total-verifications: u0,
      is-active: true,
      authorized-at: stacks-block-time
    })))

(define-public (revoke-verifier (verifier principal))
  (let ((verifier-info (unwrap! (map-get? authorized-verifiers verifier) ERR-NOT-FOUND)))
    (ok (map-set authorized-verifiers verifier
      (merge verifier-info { is-active: false })))))

(define-public (update-verification-status
    (request-id uint)
    (new-status (string-ascii 20)))
  (let ((request (unwrap! (map-get? verification-requests request-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get provider request)) ERR-NOT-AUTHORIZED)
    (ok (map-set verification-requests request-id
      (merge request { status: new-status })))))

(define-private (update-verification-history
    (provider principal)
    (credential-type (string-ascii 50))
    (is-valid bool))
  (let ((history (default-to
                  { total-verifications: u0, last-verified: u0, current-status: "none", verification-count: u0 }
                  (map-get? verification-history { provider: provider, credential-type: credential-type }))))
    (map-set verification-history { provider: provider, credential-type: credential-type }
      {
        total-verifications: (+ (get total-verifications history) u1),
        last-verified: stacks-block-time,
        current-status: (if is-valid "verified" "rejected"),
        verification-count: (+ (get verification-count history) u1)
      })
    true))

(define-read-only (get-verification-request (request-id uint))
  (ok (map-get? verification-requests request-id)))

(define-read-only (get-verification-result (result-id uint))
  (ok (map-get? verification-results result-id)))

(define-read-only (get-verifier-info (verifier principal))
  (ok (map-get? authorized-verifiers verifier)))

(define-read-only (get-verification-history (provider principal) (credential-type (string-ascii 50)))
  (ok (map-get? verification-history { provider: provider, credential-type: credential-type })))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-request-id (request-id uint))
  (ok (int-to-ascii request-id)))

(define-read-only (parse-request-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
