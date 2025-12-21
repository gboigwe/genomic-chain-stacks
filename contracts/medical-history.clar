;; medical-history - Clarity 4
;; Comprehensive patient medical history tracking

(define-constant ERR-ENTRY-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-ENTRY (err u102))

(define-map history-entries uint
  {
    patient: principal,
    event-type: (string-ascii 50),
    event-date: uint,
    description: (string-utf8 200),
    provider: principal,
    severity: (string-ascii 20),
    status: (string-ascii 20),
    data-hash: (buff 64)
  }
)

(define-map family-history uint
  {
    patient: principal,
    relationship: (string-ascii 50),
    condition: (string-utf8 200),
    age-of-onset: (optional uint),
    deceased: bool,
    notes: (string-utf8 300)
  }
)

(define-map surgical-history uint
  {
    patient: principal,
    procedure-name: (string-utf8 200),
    procedure-date: uint,
    surgeon: principal,
    hospital: (string-utf8 100),
    complications: (optional (string-utf8 300)),
    outcome: (string-ascii 50)
  }
)

(define-map medication-history uint
  {
    patient: principal,
    medication-name: (string-utf8 100),
    start-date: uint,
    end-date: (optional uint),
    dosage: (string-ascii 50),
    prescriber: principal,
    reason: (string-utf8 200),
    is-current: bool
  }
)

(define-map immunization-records uint
  {
    patient: principal,
    vaccine-name: (string-utf8 100),
    administration-date: uint,
    administered-by: principal,
    lot-number: (string-ascii 50),
    site: (string-ascii 50),
    next-due-date: (optional uint)
  }
)

(define-map social-history uint
  {
    patient: principal,
    category: (string-ascii 50),
    description: (string-utf8 300),
    start-date: uint,
    end-date: (optional uint),
    frequency: (optional (string-ascii 50)),
    recorded-at: uint
  }
)

(define-data-var entry-counter uint u0)
(define-data-var family-counter uint u0)
(define-data-var surgical-counter uint u0)
(define-data-var medication-counter uint u0)
(define-data-var immunization-counter uint u0)
(define-data-var social-counter uint u0)

(define-public (add-entry
    (patient principal)
    (event-type (string-ascii 50))
    (event-date uint)
    (description (string-utf8 200))
    (provider principal)
    (severity (string-ascii 20))
    (data-hash (buff 64)))
  (let ((entry-id (+ (var-get entry-counter) u1)))
    (map-set history-entries entry-id
      {
        patient: patient,
        event-type: event-type,
        event-date: event-date,
        description: description,
        provider: provider,
        severity: severity,
        status: "active",
        data-hash: data-hash
      })
    (var-set entry-counter entry-id)
    (ok entry-id)))

(define-public (add-family-history
    (relationship (string-ascii 50))
    (condition (string-utf8 200))
    (age-of-onset (optional uint))
    (deceased bool)
    (notes (string-utf8 300)))
  (let ((family-id (+ (var-get family-counter) u1)))
    (map-set family-history family-id
      {
        patient: tx-sender,
        relationship: relationship,
        condition: condition,
        age-of-onset: age-of-onset,
        deceased: deceased,
        notes: notes
      })
    (var-set family-counter family-id)
    (ok family-id)))

(define-public (add-surgical-history
    (procedure-name (string-utf8 200))
    (procedure-date uint)
    (surgeon principal)
    (hospital (string-utf8 100))
    (complications (optional (string-utf8 300)))
    (outcome (string-ascii 50)))
  (let ((surgical-id (+ (var-get surgical-counter) u1)))
    (map-set surgical-history surgical-id
      {
        patient: tx-sender,
        procedure-name: procedure-name,
        procedure-date: procedure-date,
        surgeon: surgeon,
        hospital: hospital,
        complications: complications,
        outcome: outcome
      })
    (var-set surgical-counter surgical-id)
    (ok surgical-id)))

(define-public (add-medication-history
    (medication-name (string-utf8 100))
    (start-date uint)
    (end-date (optional uint))
    (dosage (string-ascii 50))
    (prescriber principal)
    (reason (string-utf8 200))
    (is-current bool))
  (let ((medication-id (+ (var-get medication-counter) u1)))
    (map-set medication-history medication-id
      {
        patient: tx-sender,
        medication-name: medication-name,
        start-date: start-date,
        end-date: end-date,
        dosage: dosage,
        prescriber: prescriber,
        reason: reason,
        is-current: is-current
      })
    (var-set medication-counter medication-id)
    (ok medication-id)))

(define-public (record-immunization
    (vaccine-name (string-utf8 100))
    (administration-date uint)
    (administered-by principal)
    (lot-number (string-ascii 50))
    (site (string-ascii 50))
    (next-due-date (optional uint)))
  (let ((immunization-id (+ (var-get immunization-counter) u1)))
    (map-set immunization-records immunization-id
      {
        patient: tx-sender,
        vaccine-name: vaccine-name,
        administration-date: administration-date,
        administered-by: administered-by,
        lot-number: lot-number,
        site: site,
        next-due-date: next-due-date
      })
    (var-set immunization-counter immunization-id)
    (ok immunization-id)))

(define-public (add-social-history
    (category (string-ascii 50))
    (description (string-utf8 300))
    (start-date uint)
    (end-date (optional uint))
    (frequency (optional (string-ascii 50))))
  (let ((social-id (+ (var-get social-counter) u1)))
    (map-set social-history social-id
      {
        patient: tx-sender,
        category: category,
        description: description,
        start-date: start-date,
        end-date: end-date,
        frequency: frequency,
        recorded-at: stacks-block-time
      })
    (var-set social-counter social-id)
    (ok social-id)))

(define-public (update-entry-status
    (entry-id uint)
    (new-status (string-ascii 20)))
  (let ((entry (unwrap! (map-get? history-entries entry-id) ERR-ENTRY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get patient entry)) ERR-NOT-AUTHORIZED)
    (ok (map-set history-entries entry-id
      (merge entry { status: new-status })))))

(define-public (discontinue-medication (medication-id uint))
  (let ((medication (unwrap! (map-get? medication-history medication-id) ERR-ENTRY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get patient medication)) ERR-NOT-AUTHORIZED)
    (ok (map-set medication-history medication-id
      (merge medication {
        is-current: false,
        end-date: (some stacks-block-time)
      })))))

(define-read-only (get-entry (entry-id uint))
  (ok (map-get? history-entries entry-id)))

(define-read-only (get-family-history (family-id uint))
  (ok (map-get? family-history family-id)))

(define-read-only (get-surgical-history (surgical-id uint))
  (ok (map-get? surgical-history surgical-id)))

(define-read-only (get-medication-history (medication-id uint))
  (ok (map-get? medication-history medication-id)))

(define-read-only (get-immunization-record (immunization-id uint))
  (ok (map-get? immunization-records immunization-id)))

(define-read-only (get-social-history (social-id uint))
  (ok (map-get? social-history social-id)))

(define-read-only (validate-patient (patient principal))
  (principal-destruct? patient))

(define-read-only (format-entry-id (entry-id uint))
  (ok (int-to-ascii entry-id)))

(define-read-only (parse-entry-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
