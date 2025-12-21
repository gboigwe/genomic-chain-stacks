;; mock-health-record - Clarity 4
;; Mock health record generator for testing and development

(define-constant ERR-INVALID-INDEX (err u100))

(define-data-var record-counter uint u0)

(define-map mock-patient-records uint
  {
    patient-id: (string-ascii 50),
    age: uint,
    gender: (string-ascii 10),
    blood-type: (string-ascii 5),
    height: uint,
    weight: uint,
    created-at: uint
  }
)

(define-map mock-diagnoses uint
  {
    patient-id: (string-ascii 50),
    icd-code: (string-ascii 10),
    diagnosis-description: (string-utf8 200),
    severity: (string-ascii 20),
    diagnosed-at: uint
  }
)

(define-map mock-prescriptions uint
  {
    patient-id: (string-ascii 50),
    medication-name: (string-utf8 100),
    dosage: (string-ascii 50),
    frequency: (string-ascii 50),
    duration-days: uint,
    prescribed-at: uint
  }
)

(define-map mock-vitals uint
  {
    patient-id: (string-ascii 50),
    blood-pressure-systolic: uint,
    blood-pressure-diastolic: uint,
    heart-rate: uint,
    temperature: uint,
    oxygen-saturation: uint,
    recorded-at: uint
  }
)

(define-public (generate-mock-patient
    (patient-id (string-ascii 50))
    (age uint)
    (gender (string-ascii 10))
    (blood-type (string-ascii 5))
    (height uint)
    (weight uint))
  (let ((record-id (+ (var-get record-counter) u1)))
    (map-set mock-patient-records record-id
      {
        patient-id: patient-id,
        age: age,
        gender: gender,
        blood-type: blood-type,
        height: height,
        weight: weight,
        created-at: stacks-block-time
      })
    (var-set record-counter record-id)
    (ok record-id)))

(define-public (generate-mock-diagnosis
    (patient-id (string-ascii 50))
    (icd-code (string-ascii 10))
    (description (string-utf8 200))
    (severity (string-ascii 20)))
  (let ((diagnosis-id (+ (var-get record-counter) u1)))
    (map-set mock-diagnoses diagnosis-id
      {
        patient-id: patient-id,
        icd-code: icd-code,
        diagnosis-description: description,
        severity: severity,
        diagnosed-at: stacks-block-time
      })
    (var-set record-counter diagnosis-id)
    (ok diagnosis-id)))

(define-public (generate-mock-prescription
    (patient-id (string-ascii 50))
    (medication (string-utf8 100))
    (dosage (string-ascii 50))
    (frequency (string-ascii 50))
    (duration uint))
  (let ((prescription-id (+ (var-get record-counter) u1)))
    (map-set mock-prescriptions prescription-id
      {
        patient-id: patient-id,
        medication-name: medication,
        dosage: dosage,
        frequency: frequency,
        duration-days: duration,
        prescribed-at: stacks-block-time
      })
    (var-set record-counter prescription-id)
    (ok prescription-id)))

(define-public (generate-mock-vitals
    (patient-id (string-ascii 50))
    (systolic uint)
    (diastolic uint)
    (heart-rate uint)
    (temperature uint)
    (o2-sat uint))
  (let ((vitals-id (+ (var-get record-counter) u1)))
    (map-set mock-vitals vitals-id
      {
        patient-id: patient-id,
        blood-pressure-systolic: systolic,
        blood-pressure-diastolic: diastolic,
        heart-rate: heart-rate,
        temperature: temperature,
        oxygen-saturation: o2-sat,
        recorded-at: stacks-block-time
      })
    (var-set record-counter vitals-id)
    (ok vitals-id)))

(define-read-only (get-mock-patient (record-id uint))
  (ok (map-get? mock-patient-records record-id)))

(define-read-only (get-mock-diagnosis (diagnosis-id uint))
  (ok (map-get? mock-diagnoses diagnosis-id)))

(define-read-only (get-mock-prescription (prescription-id uint))
  (ok (map-get? mock-prescriptions prescription-id)))

(define-read-only (get-mock-vitals (vitals-id uint))
  (ok (map-get? mock-vitals vitals-id)))

(define-read-only (get-record-count)
  (ok (var-get record-counter)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-record-id (record-id uint))
  (ok (int-to-ascii record-id)))

(define-read-only (parse-record-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
