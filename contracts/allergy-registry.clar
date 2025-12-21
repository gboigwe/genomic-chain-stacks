;; allergy-registry - Clarity 4
;; Patient allergy tracking and alerts

(define-constant ERR-ALLERGY-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-SEVERITY (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))

(define-map allergies uint
  {
    patient: principal,
    allergen: (string-ascii 100),
    allergen-type: (string-ascii 50),
    severity: (string-ascii 20),
    reaction: (string-utf8 200),
    symptoms: (list 10 (string-utf8 100)),
    recorded-by: principal,
    recorded-at: uint,
    verified-by: (optional principal),
    is-active: bool
  }
)

(define-map allergy-categories uint
  {
    category-name: (string-utf8 100),
    category-type: (string-ascii 50),
    common-allergens: (list 20 (string-ascii 100)),
    created-at: uint
  }
)

(define-map patient-allergy-alerts uint
  {
    patient: principal,
    allergy-id: uint,
    alert-level: (string-ascii 20),
    alert-message: (string-utf8 500),
    triggered-at: uint,
    acknowledged: bool
  }
)

(define-map cross-reactions uint
  {
    primary-allergen: (string-ascii 100),
    cross-reactive-allergen: (string-ascii 100),
    severity-modifier: uint,
    evidence-level: (string-ascii 20),
    documented-at: uint
  }
)

(define-map allergy-verifications uint
  {
    allergy-id: uint,
    verified-by: principal,
    verification-method: (string-ascii 50),
    test-results: (optional (buff 128)),
    verified-at: uint,
    notes: (string-utf8 500)
  }
)

(define-map medication-interactions uint
  {
    allergen: (string-ascii 100),
    medication: (string-ascii 100),
    interaction-type: (string-ascii 50),
    severity: (string-ascii 20),
    recommendation: (string-utf8 300)
  }
)

(define-data-var allergy-counter uint u0)
(define-data-var category-counter uint u0)
(define-data-var alert-counter uint u0)
(define-data-var cross-reaction-counter uint u0)
(define-data-var verification-counter uint u0)
(define-data-var interaction-counter uint u0)

(define-public (register-allergy
    (patient principal)
    (allergen (string-ascii 100))
    (allergen-type (string-ascii 50))
    (severity (string-ascii 20))
    (reaction (string-utf8 200))
    (symptoms (list 10 (string-utf8 100))))
  (let ((allergy-id (+ (var-get allergy-counter) u1)))
    (map-set allergies allergy-id
      {
        patient: patient,
        allergen: allergen,
        allergen-type: allergen-type,
        severity: severity,
        reaction: reaction,
        symptoms: symptoms,
        recorded-by: tx-sender,
        recorded-at: stacks-block-time,
        verified-by: none,
        is-active: true
      })
    (var-set allergy-counter allergy-id)
    (ok allergy-id)))

(define-public (verify-allergy
    (allergy-id uint)
    (verification-method (string-ascii 50))
    (test-results (optional (buff 128)))
    (notes (string-utf8 500)))
  (let ((allergy (unwrap! (map-get? allergies allergy-id) ERR-ALLERGY-NOT-FOUND))
        (verification-id (+ (var-get verification-counter) u1)))
    (map-set allergy-verifications verification-id
      {
        allergy-id: allergy-id,
        verified-by: tx-sender,
        verification-method: verification-method,
        test-results: test-results,
        verified-at: stacks-block-time,
        notes: notes
      })
    (map-set allergies allergy-id
      (merge allergy { verified-by: (some tx-sender) }))
    (var-set verification-counter verification-id)
    (ok verification-id)))

(define-public (create-allergy-alert
    (patient principal)
    (allergy-id uint)
    (alert-level (string-ascii 20))
    (alert-message (string-utf8 500)))
  (let ((alert-id (+ (var-get alert-counter) u1)))
    (asserts! (is-some (map-get? allergies allergy-id)) ERR-ALLERGY-NOT-FOUND)
    (map-set patient-allergy-alerts alert-id
      {
        patient: patient,
        allergy-id: allergy-id,
        alert-level: alert-level,
        alert-message: alert-message,
        triggered-at: stacks-block-time,
        acknowledged: false
      })
    (var-set alert-counter alert-id)
    (ok alert-id)))

(define-public (acknowledge-alert (alert-id uint))
  (let ((alert (unwrap! (map-get? patient-allergy-alerts alert-id) ERR-ALLERGY-NOT-FOUND)))
    (ok (map-set patient-allergy-alerts alert-id
      (merge alert { acknowledged: true })))))

(define-public (add-allergy-category
    (category-name (string-utf8 100))
    (category-type (string-ascii 50))
    (common-allergens (list 20 (string-ascii 100))))
  (let ((category-id (+ (var-get category-counter) u1)))
    (map-set allergy-categories category-id
      {
        category-name: category-name,
        category-type: category-type,
        common-allergens: common-allergens,
        created-at: stacks-block-time
      })
    (var-set category-counter category-id)
    (ok category-id)))

(define-public (register-cross-reaction
    (primary-allergen (string-ascii 100))
    (cross-reactive-allergen (string-ascii 100))
    (severity-modifier uint)
    (evidence-level (string-ascii 20)))
  (let ((reaction-id (+ (var-get cross-reaction-counter) u1)))
    (map-set cross-reactions reaction-id
      {
        primary-allergen: primary-allergen,
        cross-reactive-allergen: cross-reactive-allergen,
        severity-modifier: severity-modifier,
        evidence-level: evidence-level,
        documented-at: stacks-block-time
      })
    (var-set cross-reaction-counter reaction-id)
    (ok reaction-id)))

(define-public (deactivate-allergy (allergy-id uint))
  (let ((allergy (unwrap! (map-get? allergies allergy-id) ERR-ALLERGY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get patient allergy)) ERR-NOT-AUTHORIZED)
    (ok (map-set allergies allergy-id
      (merge allergy { is-active: false })))))

(define-read-only (get-allergy (allergy-id uint))
  (ok (map-get? allergies allergy-id)))

(define-read-only (get-allergy-category (category-id uint))
  (ok (map-get? allergy-categories category-id)))

(define-read-only (get-allergy-alert (alert-id uint))
  (ok (map-get? patient-allergy-alerts alert-id)))

(define-read-only (get-cross-reaction (reaction-id uint))
  (ok (map-get? cross-reactions reaction-id)))

(define-read-only (get-verification (verification-id uint))
  (ok (map-get? allergy-verifications verification-id)))

(define-read-only (validate-patient (patient principal))
  (principal-destruct? patient))

(define-read-only (format-allergy-id (allergy-id uint))
  (ok (int-to-ascii allergy-id)))

(define-read-only (parse-allergy-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
