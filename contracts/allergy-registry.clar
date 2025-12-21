;; allergy-registry - Clarity 4
;; Patient allergy tracking and alerts

(define-constant ERR-ALLERGY-NOT-FOUND (err u100))
(define-data-var allergy-counter uint u0)

(define-map allergies { allergy-id: uint }
  { patient: principal, allergen: (string-ascii 100), severity: (string-ascii 20), reaction: (string-utf8 200), recorded-at: uint })

(define-public (register-allergy (allergen (string-ascii 100)) (severity (string-ascii 20)) (reaction (string-utf8 200)))
  (let ((new-id (+ (var-get allergy-counter) u1)))
    (map-set allergies { allergy-id: new-id }
      { patient: tx-sender, allergen: allergen, severity: severity, reaction: reaction, recorded-at: stacks-block-time })
    (var-set allergy-counter new-id)
    (ok new-id)))

(define-read-only (get-allergy (allergy-id uint))
  (ok (map-get? allergies { allergy-id: allergy-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-patient (patient principal)) (principal-destruct? patient))

;; Clarity 4: int-to-utf8
(define-read-only (format-allergy-id (allergy-id uint)) (ok (int-to-utf8 allergy-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-allergy-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
