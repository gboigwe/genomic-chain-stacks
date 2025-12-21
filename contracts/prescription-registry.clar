;; prescription-registry - Clarity 4
;; Prescription tracking and verification

(define-constant ERR-PRESCRIPTION-NOT-FOUND (err u100))
(define-data-var prescription-counter uint u0)

(define-map prescriptions { prescription-id: uint }
  { patient: principal, prescriber: principal, medication: (string-ascii 100), dosage: (string-ascii 50), issued-at: uint, expires-at: uint, is-filled: bool })

(define-public (issue-prescription (patient principal) (medication (string-ascii 100)) (dosage (string-ascii 50)) (expiration uint))
  (let ((new-id (+ (var-get prescription-counter) u1)))
    (map-set prescriptions { prescription-id: new-id }
      { patient: patient, prescriber: tx-sender, medication: medication, dosage: dosage, issued-at: stacks-block-time, expires-at: expiration, is-filled: false })
    (var-set prescription-counter new-id)
    (ok new-id)))

(define-public (mark-filled (prescription-id uint))
  (let ((rx (unwrap! (map-get? prescriptions { prescription-id: prescription-id }) ERR-PRESCRIPTION-NOT-FOUND)))
    (ok (map-set prescriptions { prescription-id: prescription-id } (merge rx { is-filled: true })))))

(define-read-only (get-prescription (prescription-id uint))
  (ok (map-get? prescriptions { prescription-id: prescription-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-prescriber (prescriber principal)) (principal-destruct? prescriber))

;; Clarity 4: int-to-ascii
(define-read-only (format-prescription-id (prescription-id uint)) (ok (int-to-ascii prescription-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-prescription-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
