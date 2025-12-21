;; risk-scoring - Clarity 4
;; Healthcare risk assessment and scoring system

(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-SCORE (err u102))

(define-map patient-risk-profiles principal
  {
    age: uint,
    chronic-conditions: uint,
    risk-score: uint,
    risk-category: (string-ascii 20),
    last-assessment: uint,
    assessment-count: uint
  }
)

(define-map risk-factors uint
  {
    patient: principal,
    factor-type: (string-ascii 50),
    severity: uint,
    identified-at: uint,
    is-active: bool
  }
)

(define-map risk-assessments uint
  {
    patient: principal,
    assessor: principal,
    total-score: uint,
    category: (string-ascii 20),
    assessment-date: uint,
    notes: (string-utf8 500)
  }
)

(define-map risk-mitigation-plans uint
  {
    patient: principal,
    plan-description: (string-utf8 500),
    target-risk-reduction: uint,
    created-at: uint,
    is-active: bool
  }
)

(define-data-var factor-counter uint u0)
(define-data-var assessment-counter uint u0)
(define-data-var plan-counter uint u0)

(define-public (create-risk-profile
    (age uint)
    (chronic-conditions uint))
  (begin
    (map-set patient-risk-profiles tx-sender
      {
        age: age,
        chronic-conditions: chronic-conditions,
        risk-score: u0,
        risk-category: "low",
        last-assessment: stacks-block-time,
        assessment-count: u0
      })
    (ok true)))

(define-public (add-risk-factor
    (factor-type (string-ascii 50))
    (severity uint))
  (let ((factor-id (+ (var-get factor-counter) u1)))
    (asserts! (<= severity u100) ERR-INVALID-SCORE)
    (map-set risk-factors factor-id
      {
        patient: tx-sender,
        factor-type: factor-type,
        severity: severity,
        identified-at: stacks-block-time,
        is-active: true
      })
    (var-set factor-counter factor-id)
    (ok factor-id)))

(define-public (conduct-risk-assessment
    (patient principal)
    (total-score uint)
    (category (string-ascii 20))
    (notes (string-utf8 500)))
  (let ((assessment-id (+ (var-get assessment-counter) u1))
        (profile (unwrap! (map-get? patient-risk-profiles patient) ERR-NOT-FOUND)))
    (asserts! (<= total-score u100) ERR-INVALID-SCORE)
    (map-set risk-assessments assessment-id
      {
        patient: patient,
        assessor: tx-sender,
        total-score: total-score,
        category: category,
        assessment-date: stacks-block-time,
        notes: notes
      })
    (map-set patient-risk-profiles patient
      (merge profile {
        risk-score: total-score,
        risk-category: category,
        last-assessment: stacks-block-time,
        assessment-count: (+ (get assessment-count profile) u1)
      }))
    (var-set assessment-counter assessment-id)
    (ok assessment-id)))

(define-public (create-mitigation-plan
    (plan-description (string-utf8 500))
    (target-risk-reduction uint))
  (let ((plan-id (+ (var-get plan-counter) u1)))
    (map-set risk-mitigation-plans plan-id
      {
        patient: tx-sender,
        plan-description: plan-description,
        target-risk-reduction: target-risk-reduction,
        created-at: stacks-block-time,
        is-active: true
      })
    (var-set plan-counter plan-id)
    (ok plan-id)))

(define-public (deactivate-risk-factor (factor-id uint))
  (let ((factor (unwrap! (map-get? risk-factors factor-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get patient factor)) ERR-NOT-AUTHORIZED)
    (ok (map-set risk-factors factor-id
      (merge factor { is-active: false })))))

(define-read-only (get-risk-profile (patient principal))
  (ok (map-get? patient-risk-profiles patient)))

(define-read-only (get-risk-factor (factor-id uint))
  (ok (map-get? risk-factors factor-id)))

(define-read-only (get-assessment (assessment-id uint))
  (ok (map-get? risk-assessments assessment-id)))

(define-read-only (get-mitigation-plan (plan-id uint))
  (ok (map-get? risk-mitigation-plans plan-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-assessment-id (assessment-id uint))
  (ok (int-to-ascii assessment-id)))

(define-read-only (parse-assessment-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
