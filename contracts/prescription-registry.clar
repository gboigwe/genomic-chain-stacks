;; prescription-registry.clar - Clarity 4
;; Prescription tracking and management

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PRESCRIPTION-NOT-FOUND (err u101))

(define-data-var prescription-counter uint u0)

(define-map prescriptions
  { prescription-id: uint }
  {
    patient: principal,
    prescriber: principal,
    medication: (string-ascii 100),
    dosage: (string-ascii 50),
    frequency: (string-ascii 50),
    duration: uint,
    prescribed-at: uint,
    expires-at: uint,
    refills-remaining: uint,
    is-filled: bool,
    pharmacy: (optional principal)
  }
)

(define-public (create-prescription
    (patient principal)
    (medication (string-ascii 100))
    (dosage (string-ascii 50))
    (frequency (string-ascii 50))
    (duration uint)
    (refills uint))
  (let
    ((new-id (+ (var-get prescription-counter) u1))
     (expiration (+ stacks-block-time duration)))
    (map-set prescriptions { prescription-id: new-id }
      {
        patient: patient,
        prescriber: tx-sender,
        medication: medication,
        dosage: dosage,
        frequency: frequency,
        duration: duration,
        prescribed-at: stacks-block-time,
        expires-at: expiration,
        refills-remaining: refills,
        is-filled: false,
        pharmacy: none
      })
    (var-set prescription-counter new-id)
    (ok new-id)))

(define-public (fill-prescription (prescription-id uint) (pharmacy principal))
  (let
    ((prescription (unwrap! (map-get? prescriptions { prescription-id: prescription-id }) ERR-PRESCRIPTION-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get patient prescription)) ERR-NOT-AUTHORIZED)
    (map-set prescriptions { prescription-id: prescription-id }
      (merge prescription { is-filled: true, pharmacy: (some pharmacy) }))
    (ok true)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-patient (patient principal))
  (principal-destruct? patient))

;; Clarity 4: int-to-ascii
(define-read-only (format-prescription-id (prescription-id uint))
  (ok (int-to-ascii prescription-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-prescription-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-height)
  (ok burn-block-height))

(define-read-only (get-prescription (prescription-id uint))
  (ok (map-get? prescriptions { prescription-id: prescription-id })))

(define-read-only (is-prescription-valid (prescription-id uint))
  (match (map-get? prescriptions { prescription-id: prescription-id })
    prescription (ok (< stacks-block-time (get expires-at prescription)))
    (ok false)))
