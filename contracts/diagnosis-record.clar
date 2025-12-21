;; diagnosis-record - Clarity 4
;; Medical diagnosis records and tracking

(define-constant ERR-DIAGNOSIS-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-ICD-CODE (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))

(define-map diagnoses uint
  {
    patient: principal,
    provider: principal,
    icd-code: (string-ascii 20),
    diagnosis-name: (string-utf8 200),
    description: (string-utf8 500),
    diagnosed-at: uint,
    severity: (string-ascii 20),
    status: (string-ascii 20),
    confidence-level: uint,
    is-primary: bool
  }
)

(define-map diagnosis-history uint
  {
    diagnosis-id: uint,
    previous-status: (string-ascii 20),
    new-status: (string-ascii 20),
    updated-by: principal,
    updated-at: uint,
    notes: (string-utf8 300)
  }
)

(define-map treatment-plans uint
  {
    diagnosis-id: uint,
    plan-description: (string-utf8 500),
    medications: (list 10 (string-utf8 100)),
    procedures: (list 10 (string-utf8 100)),
    start-date: uint,
    end-date: (optional uint),
    provider: principal
  }
)

(define-map follow-ups uint
  {
    diagnosis-id: uint,
    follow-up-date: uint,
    follow-up-type: (string-ascii 50),
    provider: principal,
    notes: (string-utf8 500),
    outcome: (optional (string-utf8 300)),
    completed: bool
  }
)

(define-map differential-diagnoses uint
  {
    primary-diagnosis-id: uint,
    alternative-icd-code: (string-ascii 20),
    alternative-name: (string-utf8 200),
    probability: uint,
    ruled-out: bool,
    ruled-out-reason: (optional (string-utf8 300))
  }
)

(define-map comorbidities uint
  {
    primary-diagnosis-id: uint,
    comorbid-diagnosis-id: uint,
    relationship-type: (string-ascii 50),
    impact-level: (string-ascii 20),
    documented-at: uint
  }
)

(define-data-var diagnosis-counter uint u0)
(define-data-var history-counter uint u0)
(define-data-var treatment-counter uint u0)
(define-data-var followup-counter uint u0)
(define-data-var differential-counter uint u0)
(define-data-var comorbidity-counter uint u0)

(define-public (record-diagnosis
    (patient principal)
    (icd-code (string-ascii 20))
    (diagnosis-name (string-utf8 200))
    (description (string-utf8 500))
    (severity (string-ascii 20))
    (confidence-level uint)
    (is-primary bool))
  (let ((diagnosis-id (+ (var-get diagnosis-counter) u1)))
    (map-set diagnoses diagnosis-id
      {
        patient: patient,
        provider: tx-sender,
        icd-code: icd-code,
        diagnosis-name: diagnosis-name,
        description: description,
        diagnosed-at: stacks-block-time,
        severity: severity,
        status: "active",
        confidence-level: confidence-level,
        is-primary: is-primary
      })
    (var-set diagnosis-counter diagnosis-id)
    (ok diagnosis-id)))

(define-public (update-diagnosis-status
    (diagnosis-id uint)
    (new-status (string-ascii 20))
    (notes (string-utf8 300)))
  (let ((diagnosis (unwrap! (map-get? diagnoses diagnosis-id) ERR-DIAGNOSIS-NOT-FOUND))
        (history-id (+ (var-get history-counter) u1)))
    (map-set diagnosis-history history-id
      {
        diagnosis-id: diagnosis-id,
        previous-status: (get status diagnosis),
        new-status: new-status,
        updated-by: tx-sender,
        updated-at: stacks-block-time,
        notes: notes
      })
    (map-set diagnoses diagnosis-id
      (merge diagnosis { status: new-status }))
    (var-set history-counter history-id)
    (ok history-id)))

(define-public (create-treatment-plan
    (diagnosis-id uint)
    (plan-description (string-utf8 500))
    (medications (list 10 (string-utf8 100)))
    (procedures (list 10 (string-utf8 100)))
    (start-date uint)
    (end-date (optional uint)))
  (let ((treatment-id (+ (var-get treatment-counter) u1)))
    (asserts! (is-some (map-get? diagnoses diagnosis-id)) ERR-DIAGNOSIS-NOT-FOUND)
    (map-set treatment-plans treatment-id
      {
        diagnosis-id: diagnosis-id,
        plan-description: plan-description,
        medications: medications,
        procedures: procedures,
        start-date: start-date,
        end-date: end-date,
        provider: tx-sender
      })
    (var-set treatment-counter treatment-id)
    (ok treatment-id)))

(define-public (schedule-follow-up
    (diagnosis-id uint)
    (follow-up-date uint)
    (follow-up-type (string-ascii 50))
    (notes (string-utf8 500)))
  (let ((followup-id (+ (var-get followup-counter) u1)))
    (asserts! (is-some (map-get? diagnoses diagnosis-id)) ERR-DIAGNOSIS-NOT-FOUND)
    (map-set follow-ups followup-id
      {
        diagnosis-id: diagnosis-id,
        follow-up-date: follow-up-date,
        follow-up-type: follow-up-type,
        provider: tx-sender,
        notes: notes,
        outcome: none,
        completed: false
      })
    (var-set followup-counter followup-id)
    (ok followup-id)))

(define-public (add-differential-diagnosis
    (primary-diagnosis-id uint)
    (alternative-icd-code (string-ascii 20))
    (alternative-name (string-utf8 200))
    (probability uint))
  (let ((differential-id (+ (var-get differential-counter) u1)))
    (asserts! (is-some (map-get? diagnoses primary-diagnosis-id)) ERR-DIAGNOSIS-NOT-FOUND)
    (map-set differential-diagnoses differential-id
      {
        primary-diagnosis-id: primary-diagnosis-id,
        alternative-icd-code: alternative-icd-code,
        alternative-name: alternative-name,
        probability: probability,
        ruled-out: false,
        ruled-out-reason: none
      })
    (var-set differential-counter differential-id)
    (ok differential-id)))

(define-public (record-comorbidity
    (primary-diagnosis-id uint)
    (comorbid-diagnosis-id uint)
    (relationship-type (string-ascii 50))
    (impact-level (string-ascii 20)))
  (let ((comorbidity-id (+ (var-get comorbidity-counter) u1)))
    (asserts! (is-some (map-get? diagnoses primary-diagnosis-id)) ERR-DIAGNOSIS-NOT-FOUND)
    (asserts! (is-some (map-get? diagnoses comorbid-diagnosis-id)) ERR-DIAGNOSIS-NOT-FOUND)
    (map-set comorbidities comorbidity-id
      {
        primary-diagnosis-id: primary-diagnosis-id,
        comorbid-diagnosis-id: comorbid-diagnosis-id,
        relationship-type: relationship-type,
        impact-level: impact-level,
        documented-at: stacks-block-time
      })
    (var-set comorbidity-counter comorbidity-id)
    (ok comorbidity-id)))

(define-public (complete-follow-up
    (followup-id uint)
    (outcome (string-utf8 300)))
  (let ((followup (unwrap! (map-get? follow-ups followup-id) ERR-DIAGNOSIS-NOT-FOUND)))
    (ok (map-set follow-ups followup-id
      (merge followup {
        outcome: (some outcome),
        completed: true
      })))))

(define-read-only (get-diagnosis (diagnosis-id uint))
  (ok (map-get? diagnoses diagnosis-id)))

(define-read-only (get-diagnosis-history (history-id uint))
  (ok (map-get? diagnosis-history history-id)))

(define-read-only (get-treatment-plan (treatment-id uint))
  (ok (map-get? treatment-plans treatment-id)))

(define-read-only (get-follow-up (followup-id uint))
  (ok (map-get? follow-ups followup-id)))

(define-read-only (get-differential (differential-id uint))
  (ok (map-get? differential-diagnoses differential-id)))

(define-read-only (get-comorbidity (comorbidity-id uint))
  (ok (map-get? comorbidities comorbidity-id)))

(define-read-only (validate-provider (provider principal))
  (principal-destruct? provider))

(define-read-only (format-diagnosis-id (diagnosis-id uint))
  (ok (int-to-ascii diagnosis-id)))

(define-read-only (parse-diagnosis-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
