;; icd-10-registry - Clarity 4
;; ICD-10 diagnosis code registry and mapping system

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CODE-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-CODE (err u103))

(define-map icd-10-codes (string-ascii 10)
  {
    description: (string-utf8 500),
    category: (string-ascii 50),
    subcategory: (string-ascii 50),
    is-billable: bool,
    is-active: bool,
    added-at: uint
  }
)

(define-map diagnosis-records uint
  {
    patient-id: (string-ascii 50),
    icd-code: (string-ascii 10),
    diagnosed-by: principal,
    diagnosis-date: uint,
    severity: (string-ascii 20),
    notes: (string-utf8 500),
    is-primary: bool
  }
)

(define-map code-mappings { source-code: (string-ascii 10), target-system: (string-ascii 50) }
  {
    target-code: (string-ascii 10),
    mapping-confidence: uint,
    mapped-by: principal,
    mapped-at: uint
  }
)

(define-map procedure-codes (string-ascii 10)
  {
    procedure-description: (string-utf8 500),
    related-icd-codes: (list 5 (string-ascii 10)),
    typical-duration: uint,
    complexity-level: uint
  }
)

(define-map code-usage-stats (string-ascii 10)
  {
    usage-count: uint,
    last-used: uint,
    most-common-specialty: (string-ascii 50)
  }
)

(define-data-var diagnosis-counter uint u0)
(define-data-var registry-admin principal tx-sender)

(define-public (register-icd-code
    (code (string-ascii 10))
    (description (string-utf8 500))
    (category (string-ascii 50))
    (subcategory (string-ascii 50))
    (is-billable bool))
  (begin
    (asserts! (is-eq tx-sender (var-get registry-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? icd-10-codes code)) ERR-ALREADY-EXISTS)
    (ok (map-set icd-10-codes code
      {
        description: description,
        category: category,
        subcategory: subcategory,
        is-billable: is-billable,
        is-active: true,
        added-at: stacks-block-time
      }))))

(define-public (record-diagnosis
    (patient-id (string-ascii 50))
    (icd-code (string-ascii 10))
    (severity (string-ascii 20))
    (notes (string-utf8 500))
    (is-primary bool))
  (let ((diagnosis-id (+ (var-get diagnosis-counter) u1))
        (code-data (unwrap! (map-get? icd-10-codes icd-code) ERR-CODE-NOT-FOUND)))
    (asserts! (get is-active code-data) ERR-INVALID-CODE)
    (map-set diagnosis-records diagnosis-id
      {
        patient-id: patient-id,
        icd-code: icd-code,
        diagnosed-by: tx-sender,
        diagnosis-date: stacks-block-time,
        severity: severity,
        notes: notes,
        is-primary: is-primary
      })
    (update-code-usage icd-code)
    (var-set diagnosis-counter diagnosis-id)
    (ok diagnosis-id)))

(define-public (create-code-mapping
    (source-code (string-ascii 10))
    (target-system (string-ascii 50))
    (target-code (string-ascii 10))
    (confidence uint))
  (let ((source-exists (unwrap! (map-get? icd-10-codes source-code) ERR-CODE-NOT-FOUND)))
    (ok (map-set code-mappings { source-code: source-code, target-system: target-system }
      {
        target-code: target-code,
        mapping-confidence: confidence,
        mapped-by: tx-sender,
        mapped-at: stacks-block-time
      }))))

(define-public (register-procedure-code
    (code (string-ascii 10))
    (description (string-utf8 500))
    (related-icd-codes (list 5 (string-ascii 10)))
    (typical-duration uint)
    (complexity-level uint))
  (begin
    (asserts! (is-eq tx-sender (var-get registry-admin)) ERR-NOT-AUTHORIZED)
    (ok (map-set procedure-codes code
      {
        procedure-description: description,
        related-icd-codes: related-icd-codes,
        typical-duration: typical-duration,
        complexity-level: complexity-level
      }))))

(define-public (deactivate-code (code (string-ascii 10)))
  (let ((code-data (unwrap! (map-get? icd-10-codes code) ERR-CODE-NOT-FOUND)))
    (asserts! (is-eq tx-sender (var-get registry-admin)) ERR-NOT-AUTHORIZED)
    (ok (map-set icd-10-codes code
      (merge code-data { is-active: false })))))

(define-private (update-code-usage (code (string-ascii 10)))
  (let ((stats (default-to
                 { usage-count: u0, last-used: u0, most-common-specialty: "" }
                 (map-get? code-usage-stats code))))
    (map-set code-usage-stats code
      {
        usage-count: (+ (get usage-count stats) u1),
        last-used: stacks-block-time,
        most-common-specialty: (get most-common-specialty stats)
      })
    true))

(define-read-only (get-icd-code (code (string-ascii 10)))
  (ok (map-get? icd-10-codes code)))

(define-read-only (get-diagnosis (diagnosis-id uint))
  (ok (map-get? diagnosis-records diagnosis-id)))

(define-read-only (get-code-mapping (source-code (string-ascii 10)) (target-system (string-ascii 50)))
  (ok (map-get? code-mappings { source-code: source-code, target-system: target-system })))

(define-read-only (get-procedure-code (code (string-ascii 10)))
  (ok (map-get? procedure-codes code)))

(define-read-only (get-code-usage-stats (code (string-ascii 10)))
  (ok (map-get? code-usage-stats code)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-diagnosis-id (diagnosis-id uint))
  (ok (int-to-ascii diagnosis-id)))

(define-read-only (parse-diagnosis-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
