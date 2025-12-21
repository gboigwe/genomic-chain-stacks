;; validation-health - Clarity 4
;; Data validation and integrity checking for healthcare records

(define-constant ERR-VALIDATION-FAILED (err u100))
(define-constant ERR-INVALID-FORMAT (err u101))
(define-constant ERR-MISSING-REQUIRED-FIELD (err u102))

(define-map validation-rules uint
  {
    rule-name: (string-utf8 100),
    field-name: (string-ascii 50),
    validation-type: (string-ascii 50),
    min-value: (optional uint),
    max-value: (optional uint),
    is-required: bool,
    created-at: uint
  }
)

(define-map validation-results uint
  {
    data-id: uint,
    rule-id: uint,
    validated-by: principal,
    passed: bool,
    error-message: (optional (string-utf8 500)),
    validated-at: uint
  }
)

(define-map data-integrity-checks uint
  {
    data-hash: (buff 64),
    checksum: (buff 32),
    verified: bool,
    verified-by: principal,
    verified-at: uint
  }
)

(define-map schema-definitions uint
  {
    schema-name: (string-utf8 100),
    version: uint,
    required-fields: (list 20 (string-ascii 50)),
    field-types: (list 20 (string-ascii 50)),
    is-active: bool
  }
)

(define-data-var rule-counter uint u0)
(define-data-var result-counter uint u0)
(define-data-var check-counter uint u0)
(define-data-var schema-counter uint u0)

(define-public (create-validation-rule
    (rule-name (string-utf8 100))
    (field-name (string-ascii 50))
    (validation-type (string-ascii 50))
    (min-value (optional uint))
    (max-value (optional uint))
    (is-required bool))
  (let ((rule-id (+ (var-get rule-counter) u1)))
    (map-set validation-rules rule-id
      {
        rule-name: rule-name,
        field-name: field-name,
        validation-type: validation-type,
        min-value: min-value,
        max-value: max-value,
        is-required: is-required,
        created-at: stacks-block-time
      })
    (var-set rule-counter rule-id)
    (ok rule-id)))

(define-public (validate-data
    (data-id uint)
    (rule-id uint)
    (passed bool)
    (error-message (optional (string-utf8 500))))
  (let ((result-id (+ (var-get result-counter) u1)))
    (map-set validation-results result-id
      {
        data-id: data-id,
        rule-id: rule-id,
        validated-by: tx-sender,
        passed: passed,
        error-message: error-message,
        validated-at: stacks-block-time
      })
    (var-set result-counter result-id)
    (if passed
        (ok result-id)
        ERR-VALIDATION-FAILED)))

(define-public (verify-data-integrity
    (data-hash (buff 64))
    (checksum (buff 32)))
  (let ((check-id (+ (var-get check-counter) u1)))
    (map-set data-integrity-checks check-id
      {
        data-hash: data-hash,
        checksum: checksum,
        verified: true,
        verified-by: tx-sender,
        verified-at: stacks-block-time
      })
    (var-set check-counter check-id)
    (ok check-id)))

(define-public (define-schema
    (schema-name (string-utf8 100))
    (version uint)
    (required-fields (list 20 (string-ascii 50)))
    (field-types (list 20 (string-ascii 50))))
  (let ((schema-id (+ (var-get schema-counter) u1)))
    (asserts! (is-eq (len required-fields) (len field-types)) ERR-INVALID-FORMAT)
    (map-set schema-definitions schema-id
      {
        schema-name: schema-name,
        version: version,
        required-fields: required-fields,
        field-types: field-types,
        is-active: true
      })
    (var-set schema-counter schema-id)
    (ok schema-id)))

(define-read-only (get-validation-rule (rule-id uint))
  (ok (map-get? validation-rules rule-id)))

(define-read-only (get-validation-result (result-id uint))
  (ok (map-get? validation-results result-id)))

(define-read-only (get-integrity-check (check-id uint))
  (ok (map-get? data-integrity-checks check-id)))

(define-read-only (get-schema (schema-id uint))
  (ok (map-get? schema-definitions schema-id)))

(define-read-only (validate-range (value uint) (min-val uint) (max-val uint))
  (ok (and (>= value min-val) (<= value max-val))))

(define-read-only (validate-hash (data (buff 128)))
  (ok (sha256 data)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-rule-id (rule-id uint))
  (ok (int-to-ascii rule-id)))

(define-read-only (parse-rule-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
