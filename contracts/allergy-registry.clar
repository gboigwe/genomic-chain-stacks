;; allergy-registry.clar - Clarity 4
;; Patient allergy database

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALLERGY-EXISTS (err u101))

(define-map allergies
  { patient: principal, allergen: (string-ascii 100) }
  {
    severity: uint,
    reaction-type: (string-ascii 100),
    onset-date: uint,
    verified-by: principal,
    verified-at: uint,
    is-active: bool,
    notes: (string-utf8 256)
  }
)

(define-public (register-allergy
    (allergen (string-ascii 100))
    (severity uint)
    (reaction-type (string-ascii 100))
    (onset-date uint)
    (notes (string-utf8 256)))
  (begin
    (asserts! (is-none (map-get? allergies { patient: tx-sender, allergen: allergen })) ERR-ALLERGY-EXISTS)
    (map-set allergies { patient: tx-sender, allergen: allergen }
      {
        severity: severity,
        reaction-type: reaction-type,
        onset-date: onset-date,
        verified-by: tx-sender,
        verified-at: stacks-block-time,
        is-active: true,
        notes: notes
      })
    (ok true)))

(define-public (update-allergy-status
    (allergen (string-ascii 100))
    (is-active bool))
  (let
    ((allergy (unwrap! (map-get? allergies { patient: tx-sender, allergen: allergen }) ERR-NOT-AUTHORIZED)))
    (map-set allergies { patient: tx-sender, allergen: allergen }
      (merge allergy { is-active: is-active }))
    (ok true)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-patient (patient principal))
  (principal-destruct? patient))

;; Clarity 4: int-to-utf8
(define-read-only (format-severity (severity uint))
  (ok (int-to-utf8 severity)))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-height)
  (ok burn-block-height))

(define-read-only (get-allergy (patient principal) (allergen (string-ascii 100)))
  (ok (map-get? allergies { patient: patient, allergen: allergen })))

(define-read-only (has-active-allergy (patient principal) (allergen (string-ascii 100)))
  (match (map-get? allergies { patient: patient, allergen: allergen })
    allergy (ok (get is-active allergy))
    (ok false)))
