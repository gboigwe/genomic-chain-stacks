;; test-patient - Clarity 4
;; Mock patient data generator for testing healthcare platform

(define-constant ERR-INVALID-DATA (err u100))

(define-map test-patients uint
  {
    patient-id: (string-ascii 50),
    full-name: (string-utf8 200),
    date-of-birth: uint,
    gender: (string-ascii 20),
    blood-type: (string-ascii 5),
    created-at: uint,
    is-mock: bool
  }
)

(define-map test-medical-records uint
  {
    patient-id: uint,
    record-type: (string-ascii 50),
    diagnosis: (string-utf8 200),
    treatment: (string-utf8 200),
    provider: principal,
    recorded-at: uint
  }
)

(define-map test-appointments uint
  {
    patient-id: uint,
    provider: principal,
    appointment-type: (string-ascii 50),
    scheduled-time: uint,
    status: (string-ascii 20),
    notes: (string-utf8 500)
  }
)

(define-map test-prescriptions uint
  {
    patient-id: uint,
    medication-name: (string-utf8 100),
    dosage: (string-ascii 50),
    frequency: (string-ascii 50),
    prescribed-by: principal,
    prescribed-at: uint
  }
)

(define-data-var patient-counter uint u0)
(define-data-var record-counter uint u0)
(define-data-var appointment-counter uint u0)
(define-data-var prescription-counter uint u0)

(define-public (create-test-patient
    (patient-id (string-ascii 50))
    (full-name (string-utf8 200))
    (date-of-birth uint)
    (gender (string-ascii 20))
    (blood-type (string-ascii 5)))
  (let ((id (+ (var-get patient-counter) u1)))
    (map-set test-patients id
      {
        patient-id: patient-id,
        full-name: full-name,
        date-of-birth: date-of-birth,
        gender: gender,
        blood-type: blood-type,
        created-at: stacks-block-time,
        is-mock: true
      })
    (var-set patient-counter id)
    (ok id)))

(define-public (add-test-medical-record
    (patient-id uint)
    (record-type (string-ascii 50))
    (diagnosis (string-utf8 200))
    (treatment (string-utf8 200))
    (provider principal))
  (let ((record-id (+ (var-get record-counter) u1)))
    (map-set test-medical-records record-id
      {
        patient-id: patient-id,
        record-type: record-type,
        diagnosis: diagnosis,
        treatment: treatment,
        provider: provider,
        recorded-at: stacks-block-time
      })
    (var-set record-counter record-id)
    (ok record-id)))

(define-public (schedule-test-appointment
    (patient-id uint)
    (provider principal)
    (appointment-type (string-ascii 50))
    (scheduled-time uint)
    (notes (string-utf8 500)))
  (let ((appointment-id (+ (var-get appointment-counter) u1)))
    (map-set test-appointments appointment-id
      {
        patient-id: patient-id,
        provider: provider,
        appointment-type: appointment-type,
        scheduled-time: scheduled-time,
        status: "scheduled",
        notes: notes
      })
    (var-set appointment-counter appointment-id)
    (ok appointment-id)))

(define-public (create-test-prescription
    (patient-id uint)
    (medication-name (string-utf8 100))
    (dosage (string-ascii 50))
    (frequency (string-ascii 50))
    (prescribed-by principal))
  (let ((prescription-id (+ (var-get prescription-counter) u1)))
    (map-set test-prescriptions prescription-id
      {
        patient-id: patient-id,
        medication-name: medication-name,
        dosage: dosage,
        frequency: frequency,
        prescribed-by: prescribed-by,
        prescribed-at: stacks-block-time
      })
    (var-set prescription-counter prescription-id)
    (ok prescription-id)))

(define-read-only (get-test-patient (patient-id uint))
  (ok (map-get? test-patients patient-id)))

(define-read-only (get-test-record (record-id uint))
  (ok (map-get? test-medical-records record-id)))

(define-read-only (get-test-appointment (appointment-id uint))
  (ok (map-get? test-appointments appointment-id)))

(define-read-only (get-test-prescription (prescription-id uint))
  (ok (map-get? test-prescriptions prescription-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-patient-id (patient-id uint))
  (ok (int-to-ascii patient-id)))

(define-read-only (parse-patient-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
