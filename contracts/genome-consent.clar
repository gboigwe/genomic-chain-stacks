;; genome-consent - Clarity 4
;; Patient consent management for genomic data usage

(define-constant ERR-CONSENT-NOT-FOUND (err u100))
(define-data-var consent-counter uint u0)

(define-map consents { consent-id: uint }
  { patient: principal, purpose: (string-ascii 100), granted-at: uint, revoked-at: (optional uint), is-active: bool })

(define-public (grant-consent (purpose (string-ascii 100)))
  (let ((new-id (+ (var-get consent-counter) u1)))
    (map-set consents { consent-id: new-id }
      { patient: tx-sender, purpose: purpose, granted-at: stacks-block-time, revoked-at: none, is-active: true })
    (var-set consent-counter new-id)
    (ok new-id)))

(define-public (revoke-consent (consent-id uint))
  (let ((consent (unwrap! (map-get? consents { consent-id: consent-id }) ERR-CONSENT-NOT-FOUND)))
    (ok (map-set consents { consent-id: consent-id }
      (merge consent { revoked-at: (some stacks-block-time), is-active: false })))))

(define-read-only (get-consent (consent-id uint))
  (ok (map-get? consents { consent-id: consent-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-patient (patient principal)) (principal-destruct? patient))

;; Clarity 4: int-to-ascii
(define-read-only (format-consent-id (consent-id uint)) (ok (int-to-ascii consent-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-consent-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
