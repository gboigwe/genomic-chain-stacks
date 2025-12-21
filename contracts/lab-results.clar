;; lab-results - Clarity 4
;; Laboratory test results management

(define-constant ERR-RESULT-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-RESULT (err u102))

(define-map lab-results uint
  {
    patient: principal,
    lab: principal,
    test-type: (string-ascii 100),
    result-hash: (buff 64),
    performed-at: uint,
    is-verified: bool,
    urgency-level: (string-ascii 20),
    reviewed-by: (optional principal)
  }
)

(define-map test-panels uint
  {
    panel-name: (string-utf8 100),
    tests-included: (list 20 (string-ascii 100)),
    panel-type: (string-ascii 50),
    created-at: uint,
    is-active: bool
  }
)

(define-map result-interpretations uint
  {
    result-id: uint,
    interpreter: principal,
    interpretation: (string-utf8 500),
    clinical-significance: (string-ascii 50),
    interpreted-at: uint,
    confidence-level: uint
  }
)

(define-map reference-ranges uint
  {
    test-type: (string-ascii 100),
    min-value: uint,
    max-value: uint,
    unit: (string-ascii 20),
    age-range: (string-ascii 50),
    gender-specific: bool
  }
)

(define-map abnormal-flags uint
  {
    result-id: uint,
    flag-type: (string-ascii 50),
    severity: (string-ascii 20),
    flagged-at: uint,
    flagged-by: principal,
    follow-up-required: bool
  }
)

(define-map quality-controls uint
  {
    lab: principal,
    control-type: (string-ascii 50),
    control-result: (string-ascii 50),
    tested-at: uint,
    passed: bool,
    comments: (optional (string-utf8 300))
  }
)

(define-data-var result-counter uint u0)
(define-data-var panel-counter uint u0)
(define-data-var interpretation-counter uint u0)
(define-data-var range-counter uint u0)
(define-data-var flag-counter uint u0)
(define-data-var qc-counter uint u0)

(define-public (submit-result
    (patient principal)
    (test-type (string-ascii 100))
    (result-hash (buff 64))
    (urgency-level (string-ascii 20)))
  (let ((result-id (+ (var-get result-counter) u1)))
    (map-set lab-results result-id
      {
        patient: patient,
        lab: tx-sender,
        test-type: test-type,
        result-hash: result-hash,
        performed-at: stacks-block-time,
        is-verified: false,
        urgency-level: urgency-level,
        reviewed-by: none
      })
    (var-set result-counter result-id)
    (ok result-id)))

(define-public (verify-result (result-id uint))
  (let ((result (unwrap! (map-get? lab-results result-id) ERR-RESULT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get lab result)) ERR-NOT-AUTHORIZED)
    (ok (map-set lab-results result-id
      (merge result {
        is-verified: true,
        reviewed-by: (some tx-sender)
      })))))

(define-public (create-test-panel
    (panel-name (string-utf8 100))
    (tests-included (list 20 (string-ascii 100)))
    (panel-type (string-ascii 50)))
  (let ((panel-id (+ (var-get panel-counter) u1)))
    (map-set test-panels panel-id
      {
        panel-name: panel-name,
        tests-included: tests-included,
        panel-type: panel-type,
        created-at: stacks-block-time,
        is-active: true
      })
    (var-set panel-counter panel-id)
    (ok panel-id)))

(define-public (add-interpretation
    (result-id uint)
    (interpretation (string-utf8 500))
    (clinical-significance (string-ascii 50))
    (confidence-level uint))
  (let ((interpretation-id (+ (var-get interpretation-counter) u1)))
    (asserts! (is-some (map-get? lab-results result-id)) ERR-RESULT-NOT-FOUND)
    (map-set result-interpretations interpretation-id
      {
        result-id: result-id,
        interpreter: tx-sender,
        interpretation: interpretation,
        clinical-significance: clinical-significance,
        interpreted-at: stacks-block-time,
        confidence-level: confidence-level
      })
    (var-set interpretation-counter interpretation-id)
    (ok interpretation-id)))

(define-public (set-reference-range
    (test-type (string-ascii 100))
    (min-value uint)
    (max-value uint)
    (unit (string-ascii 20))
    (age-range (string-ascii 50))
    (gender-specific bool))
  (let ((range-id (+ (var-get range-counter) u1)))
    (map-set reference-ranges range-id
      {
        test-type: test-type,
        min-value: min-value,
        max-value: max-value,
        unit: unit,
        age-range: age-range,
        gender-specific: gender-specific
      })
    (var-set range-counter range-id)
    (ok range-id)))

(define-public (flag-abnormal-result
    (result-id uint)
    (flag-type (string-ascii 50))
    (severity (string-ascii 20))
    (follow-up-required bool))
  (let ((flag-id (+ (var-get flag-counter) u1)))
    (asserts! (is-some (map-get? lab-results result-id)) ERR-RESULT-NOT-FOUND)
    (map-set abnormal-flags flag-id
      {
        result-id: result-id,
        flag-type: flag-type,
        severity: severity,
        flagged-at: stacks-block-time,
        flagged-by: tx-sender,
        follow-up-required: follow-up-required
      })
    (var-set flag-counter flag-id)
    (ok flag-id)))

(define-public (record-quality-control
    (control-type (string-ascii 50))
    (control-result (string-ascii 50))
    (passed bool)
    (comments (optional (string-utf8 300))))
  (let ((qc-id (+ (var-get qc-counter) u1)))
    (map-set quality-controls qc-id
      {
        lab: tx-sender,
        control-type: control-type,
        control-result: control-result,
        tested-at: stacks-block-time,
        passed: passed,
        comments: comments
      })
    (var-set qc-counter qc-id)
    (ok qc-id)))

(define-read-only (get-result (result-id uint))
  (ok (map-get? lab-results result-id)))

(define-read-only (get-test-panel (panel-id uint))
  (ok (map-get? test-panels panel-id)))

(define-read-only (get-interpretation (interpretation-id uint))
  (ok (map-get? result-interpretations interpretation-id)))

(define-read-only (get-reference-range (range-id uint))
  (ok (map-get? reference-ranges range-id)))

(define-read-only (get-abnormal-flag (flag-id uint))
  (ok (map-get? abnormal-flags flag-id)))

(define-read-only (get-quality-control (qc-id uint))
  (ok (map-get? quality-controls qc-id)))

(define-read-only (validate-lab (lab principal))
  (principal-destruct? lab))

(define-read-only (format-result-id (result-id uint))
  (ok (int-to-ascii result-id)))

(define-read-only (parse-result-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
