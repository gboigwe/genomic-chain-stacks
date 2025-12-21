;; provider-registry - Clarity 4
;; Comprehensive healthcare provider registry and credential management

(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-CREDENTIALS (err u103))

(define-map healthcare-providers principal
  {
    provider-name: (string-utf8 200),
    provider-type: (string-ascii 50),
    license-number: (string-ascii 100),
    specialization: (string-ascii 100),
    license-expiry: uint,
    institution: (string-utf8 200),
    contact-info: (string-utf8 100),
    is-active: bool,
    registered-at: uint
  }
)

(define-map provider-credentials { provider: principal, credential-type: (string-ascii 50) }
  {
    credential-name: (string-utf8 100),
    issuing-authority: (string-utf8 200),
    credential-number: (string-ascii 100),
    issued-at: uint,
    expires-at: uint,
    is-verified: bool
  }
)

(define-map provider-specializations { provider: principal, specialization-id: uint }
  {
    specialization-name: (string-ascii 100),
    certification-authority: (string-utf8 200),
    years-of-experience: uint,
    is-board-certified: bool
  }
)

(define-map provider-reputation principal
  {
    total-patients-served: uint,
    average-rating: uint,
    total-reviews: uint,
    compliance-score: uint,
    last-audit: uint
  }
)

(define-data-var provider-counter uint u0)
(define-data-var specialization-counter uint u0)

(define-public (register-provider
    (provider-name (string-utf8 200))
    (provider-type (string-ascii 50))
    (license-number (string-ascii 100))
    (specialization (string-ascii 100))
    (license-expiry uint)
    (institution (string-utf8 200))
    (contact-info (string-utf8 100)))
  (begin
    (asserts! (is-none (map-get? healthcare-providers tx-sender)) ERR-ALREADY-EXISTS)
    (map-set healthcare-providers tx-sender
      {
        provider-name: provider-name,
        provider-type: provider-type,
        license-number: license-number,
        specialization: specialization,
        license-expiry: license-expiry,
        institution: institution,
        contact-info: contact-info,
        is-active: true,
        registered-at: stacks-block-time
      })
    (map-set provider-reputation tx-sender
      {
        total-patients-served: u0,
        average-rating: u0,
        total-reviews: u0,
        compliance-score: u100,
        last-audit: stacks-block-time
      })
    (ok true)))

(define-public (add-credential
    (credential-type (string-ascii 50))
    (credential-name (string-utf8 100))
    (issuing-authority (string-utf8 200))
    (credential-number (string-ascii 100))
    (duration uint))
  (let ((provider (unwrap! (map-get? healthcare-providers tx-sender) ERR-NOT-FOUND)))
    (asserts! (get is-active provider) ERR-NOT-AUTHORIZED)
    (ok (map-set provider-credentials { provider: tx-sender, credential-type: credential-type }
      {
        credential-name: credential-name,
        issuing-authority: issuing-authority,
        credential-number: credential-number,
        issued-at: stacks-block-time,
        expires-at: (+ stacks-block-time duration),
        is-verified: false
      }))))

(define-public (verify-credential
    (provider principal)
    (credential-type (string-ascii 50)))
  (let ((credential (unwrap! (map-get? provider-credentials { provider: provider, credential-type: credential-type }) ERR-NOT-FOUND)))
    (ok (map-set provider-credentials { provider: provider, credential-type: credential-type }
      (merge credential { is-verified: true })))))

(define-public (add-specialization
    (specialization-name (string-ascii 100))
    (certification-authority (string-utf8 200))
    (years-of-experience uint)
    (is-board-certified bool))
  (let ((provider (unwrap! (map-get? healthcare-providers tx-sender) ERR-NOT-FOUND))
        (specialization-id (+ (var-get specialization-counter) u1)))
    (asserts! (get is-active provider) ERR-NOT-AUTHORIZED)
    (map-set provider-specializations { provider: tx-sender, specialization-id: specialization-id }
      {
        specialization-name: specialization-name,
        certification-authority: certification-authority,
        years-of-experience: years-of-experience,
        is-board-certified: is-board-certified
      })
    (var-set specialization-counter specialization-id)
    (ok specialization-id)))

(define-public (update-reputation
    (total-patients uint)
    (average-rating uint)
    (total-reviews uint))
  (let ((provider (unwrap! (map-get? healthcare-providers tx-sender) ERR-NOT-FOUND))
        (reputation (unwrap! (map-get? provider-reputation tx-sender) ERR-NOT-FOUND)))
    (asserts! (get is-active provider) ERR-NOT-AUTHORIZED)
    (ok (map-set provider-reputation tx-sender
      (merge reputation {
        total-patients-served: total-patients,
        average-rating: average-rating,
        total-reviews: total-reviews
      })))))

(define-public (deactivate-provider)
  (let ((provider (unwrap! (map-get? healthcare-providers tx-sender) ERR-NOT-FOUND)))
    (ok (map-set healthcare-providers tx-sender
      (merge provider { is-active: false })))))

(define-read-only (get-provider (provider principal))
  (ok (map-get? healthcare-providers provider)))

(define-read-only (get-credential (provider principal) (credential-type (string-ascii 50)))
  (ok (map-get? provider-credentials { provider: provider, credential-type: credential-type })))

(define-read-only (get-specialization (provider principal) (specialization-id uint))
  (ok (map-get? provider-specializations { provider: provider, specialization-id: specialization-id })))

(define-read-only (get-reputation (provider principal))
  (ok (map-get? provider-reputation provider)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-provider-id (provider-id uint))
  (ok (int-to-ascii provider-id)))

(define-read-only (parse-provider-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
