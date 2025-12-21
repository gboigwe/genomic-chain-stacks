;; research-consent.clar - Clarity 4
;; Research-specific consent management

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CONSENT-EXISTS (err u101))

(define-map research-consents
  { participant: principal, project-id: uint }
  {
    granted: bool,
    granted-at: uint,
    consent-form-hash: (buff 32),
    withdrawal-allowed: bool,
    data-usage-scope: (string-utf8 256),
    compensation-agreed: uint
  }
)

(define-public (grant-research-consent
    (project-id uint)
    (consent-form-hash (buff 32))
    (data-usage-scope (string-utf8 256))
    (compensation uint))
  (begin
    (asserts! (is-none (map-get? research-consents { participant: tx-sender, project-id: project-id })) ERR-CONSENT-EXISTS)
    (map-set research-consents { participant: tx-sender, project-id: project-id }
      {
        granted: true,
        granted-at: stacks-block-time,
        consent-form-hash: consent-form-hash,
        withdrawal-allowed: true,
        data-usage-scope: data-usage-scope,
        compensation-agreed: compensation
      })
    (ok true)))

(define-public (withdraw-consent (project-id uint))
  (begin
    (map-delete research-consents { participant: tx-sender, project-id: project-id })
    (ok true)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-participant (participant principal))
  (principal-destruct? participant))

;; Clarity 4: int-to-utf8
(define-read-only (format-project-id (project-id uint))
  (ok (int-to-utf8 project-id)))

;; Clarity 4: buff-to-uint-le
(define-read-only (hash-to-number (hash-buff (buff 16)))
  (ok (buff-to-uint-le hash-buff)))

(define-read-only (get-consent (participant principal) (project-id uint))
  (ok (map-get? research-consents { participant: participant, project-id: project-id })))

(define-read-only (has-valid-consent (participant principal) (project-id uint))
  (match (map-get? research-consents { participant: participant, project-id: project-id })
    consent (ok (get granted consent))
    (ok false)))
