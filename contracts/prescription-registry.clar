;; prescription-registry - Clarity 4
;; Prescription tracking and verification

(define-constant ERR-PRESCRIPTION-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-PRESCRIPTION-EXPIRED (err u102))
(define-constant ERR-ALREADY-FILLED (err u103))

(define-map prescriptions uint
  {
    patient: principal,
    prescriber: principal,
    medication: (string-ascii 100),
    dosage: (string-ascii 50),
    frequency: (string-ascii 50),
    quantity: uint,
    refills-allowed: uint,
    refills-remaining: uint,
    issued-at: uint,
    expires-at: uint,
    is-filled: bool,
    is-controlled: bool
  }
)

(define-map prescription-fills uint
  {
    prescription-id: uint,
    pharmacy: principal,
    filled-at: uint,
    quantity-dispensed: uint,
    pharmacist: principal,
    fill-number: uint,
    notes: (optional (string-utf8 300))
  }
)

(define-map medication-interactions uint
  {
    prescription-id: uint,
    interacting-medication: (string-ascii 100),
    interaction-severity: (string-ascii 20),
    interaction-type: (string-ascii 50),
    warnings: (string-utf8 500),
    documented-at: uint
  }
)

(define-map controlled-substance-logs uint
  {
    prescription-id: uint,
    action: (string-ascii 50),
    performed-by: principal,
    verification-code: (string-ascii 100),
    logged-at: uint,
    compliance-check: bool
  }
)

(define-map prescription-verifications uint
  {
    prescription-id: uint,
    verifier: principal,
    verification-method: (string-ascii 50),
    verified-at: uint,
    is-valid: bool,
    notes: (optional (string-utf8 300))
  }
)

(define-data-var prescription-counter uint u0)
(define-data-var fill-counter uint u0)
(define-data-var interaction-counter uint u0)
(define-data-var log-counter uint u0)
(define-data-var verification-counter uint u0)

(define-public (issue-prescription
    (patient principal)
    (medication (string-ascii 100))
    (dosage (string-ascii 50))
    (frequency (string-ascii 50))
    (quantity uint)
    (refills-allowed uint)
    (expiration uint)
    (is-controlled bool))
  (let ((rx-id (+ (var-get prescription-counter) u1)))
    (map-set prescriptions rx-id
      {
        patient: patient,
        prescriber: tx-sender,
        medication: medication,
        dosage: dosage,
        frequency: frequency,
        quantity: quantity,
        refills-allowed: refills-allowed,
        refills-remaining: refills-allowed,
        issued-at: stacks-block-time,
        expires-at: expiration,
        is-filled: false,
        is-controlled: is-controlled
      })
    (var-set prescription-counter rx-id)
    (ok rx-id)))

(define-public (fill-prescription
    (prescription-id uint)
    (quantity-dispensed uint)
    (pharmacist principal)
    (notes (optional (string-utf8 300))))
  (let ((rx (unwrap! (map-get? prescriptions prescription-id) ERR-PRESCRIPTION-NOT-FOUND))
        (fill-id (+ (var-get fill-counter) u1))
        (current-fill-number (+ (- (get refills-allowed rx) (get refills-remaining rx)) u1)))
    (asserts! (> (get refills-remaining rx) u0) ERR-ALREADY-FILLED)
    (asserts! (> (get expires-at rx) stacks-block-time) ERR-PRESCRIPTION-EXPIRED)
    (map-set prescription-fills fill-id
      {
        prescription-id: prescription-id,
        pharmacy: tx-sender,
        filled-at: stacks-block-time,
        quantity-dispensed: quantity-dispensed,
        pharmacist: pharmacist,
        fill-number: current-fill-number,
        notes: notes
      })
    (map-set prescriptions prescription-id
      (merge rx {
        refills-remaining: (- (get refills-remaining rx) u1),
        is-filled: true
      }))
    (var-set fill-counter fill-id)
    (ok fill-id)))

(define-public (check-medication-interaction
    (prescription-id uint)
    (interacting-medication (string-ascii 100))
    (interaction-severity (string-ascii 20))
    (interaction-type (string-ascii 50))
    (warnings (string-utf8 500)))
  (let ((interaction-id (+ (var-get interaction-counter) u1)))
    (asserts! (is-some (map-get? prescriptions prescription-id)) ERR-PRESCRIPTION-NOT-FOUND)
    (map-set medication-interactions interaction-id
      {
        prescription-id: prescription-id,
        interacting-medication: interacting-medication,
        interaction-severity: interaction-severity,
        interaction-type: interaction-type,
        warnings: warnings,
        documented-at: stacks-block-time
      })
    (var-set interaction-counter interaction-id)
    (ok interaction-id)))

(define-public (log-controlled-substance-action
    (prescription-id uint)
    (action (string-ascii 50))
    (verification-code (string-ascii 100))
    (compliance-check bool))
  (let ((log-id (+ (var-get log-counter) u1)))
    (map-set controlled-substance-logs log-id
      {
        prescription-id: prescription-id,
        action: action,
        performed-by: tx-sender,
        verification-code: verification-code,
        logged-at: stacks-block-time,
        compliance-check: compliance-check
      })
    (var-set log-counter log-id)
    (ok log-id)))

(define-read-only (get-prescription (prescription-id uint))
  (ok (map-get? prescriptions prescription-id)))

(define-read-only (get-fill (fill-id uint))
  (ok (map-get? prescription-fills fill-id)))

(define-read-only (get-interaction (interaction-id uint))
  (ok (map-get? medication-interactions interaction-id)))

(define-read-only (get-controlled-substance-log (log-id uint))
  (ok (map-get? controlled-substance-logs log-id)))

(define-read-only (validate-prescriber (prescriber principal))
  (principal-destruct? prescriber))

(define-read-only (format-prescription-id (prescription-id uint))
  (ok (int-to-ascii prescription-id)))

(define-read-only (parse-prescription-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
