;; research-consent - Clarity 4
;; Patient consent for research participation

(define-constant ERR-CONSENT-NOT-FOUND (err u100))
(define-data-var consent-counter uint u0)

(define-map research-consents { consent-id: uint }
  { patient: principal, project-id: uint, consent-type: (string-ascii 50), granted-at: uint, expires-at: uint, is-active: bool })

(define-public (grant-consent (project-id uint) (consent-type (string-ascii 50)) (expiration uint))
  (let ((new-id (+ (var-get consent-counter) u1)))
    (map-set research-consents { consent-id: new-id }
      { patient: tx-sender, project-id: project-id, consent-type: consent-type, granted-at: stacks-block-time, expires-at: expiration, is-active: true })
    (var-set consent-counter new-id)
    (ok new-id)))

(define-public (revoke-consent (consent-id uint))
  (let ((consent (unwrap! (map-get? research-consents { consent-id: consent-id }) ERR-CONSENT-NOT-FOUND)))
    (ok (map-set research-consents { consent-id: consent-id } (merge consent { is-active: false })))))

(define-read-only (get-consent (consent-id uint))
  (ok (map-get? research-consents { consent-id: consent-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-patient (patient principal)) (principal-destruct? patient))

;; Clarity 4: int-to-utf8
(define-read-only (format-consent-id (consent-id uint)) (ok (int-to-utf8 consent-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-consent-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
