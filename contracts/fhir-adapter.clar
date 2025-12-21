;; fhir-adapter - Clarity 4
;; FHIR (Fast Healthcare Interoperability Resources) standard adapter

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-RESOURCE-NOT-FOUND (err u101))
(define-constant ERR-INVALID-FORMAT (err u102))
(define-constant ERR-VERSION-MISMATCH (err u103))

(define-map fhir-resources uint
  {
    resource-type: (string-ascii 50),
    resource-id: (string-ascii 100),
    fhir-version: (string-ascii 10),
    resource-hash: (buff 64),
    owner: principal,
    created-at: uint,
    last-updated: uint,
    is-active: bool
  }
)

(define-map resource-mappings { source-system: (string-ascii 50), external-id: (string-ascii 100) }
  {
    internal-resource-id: uint,
    mapping-version: uint,
    mapped-at: uint,
    is-verified: bool
  }
)

(define-map fhir-extensions uint
  {
    resource-id: uint,
    extension-url: (string-utf8 256),
    extension-value-hash: (buff 64),
    extension-type: (string-ascii 50)
  }
)

(define-map validation-results uint
  {
    resource-id: uint,
    validator: principal,
    is-valid: bool,
    validation-errors: (list 10 (string-ascii 100)),
    validated-at: uint
  }
)

(define-data-var resource-counter uint u0)
(define-data-var extension-counter uint u0)
(define-data-var validation-counter uint u0)
(define-data-var supported-version (string-ascii 10) "R4")

(define-public (register-fhir-resource
    (resource-type (string-ascii 50))
    (resource-id (string-ascii 100))
    (fhir-version (string-ascii 10))
    (resource-hash (buff 64)))
  (let ((internal-id (+ (var-get resource-counter) u1)))
    (asserts! (is-eq fhir-version (var-get supported-version)) ERR-VERSION-MISMATCH)
    (map-set fhir-resources internal-id
      {
        resource-type: resource-type,
        resource-id: resource-id,
        fhir-version: fhir-version,
        resource-hash: resource-hash,
        owner: tx-sender,
        created-at: stacks-block-time,
        last-updated: stacks-block-time,
        is-active: true
      })
    (var-set resource-counter internal-id)
    (ok internal-id)))

(define-public (create-resource-mapping
    (source-system (string-ascii 50))
    (external-id (string-ascii 100))
    (internal-resource-id uint)
    (mapping-version uint))
  (let ((resource (unwrap! (map-get? fhir-resources internal-resource-id) ERR-RESOURCE-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner resource)) ERR-NOT-AUTHORIZED)
    (ok (map-set resource-mappings { source-system: source-system, external-id: external-id }
      {
        internal-resource-id: internal-resource-id,
        mapping-version: mapping-version,
        mapped-at: stacks-block-time,
        is-verified: false
      }))))

(define-public (add-extension
    (resource-id uint)
    (extension-url (string-utf8 256))
    (extension-value-hash (buff 64))
    (extension-type (string-ascii 50)))
  (let ((resource (unwrap! (map-get? fhir-resources resource-id) ERR-RESOURCE-NOT-FOUND))
        (extension-id (+ (var-get extension-counter) u1)))
    (asserts! (is-eq tx-sender (get owner resource)) ERR-NOT-AUTHORIZED)
    (map-set fhir-extensions extension-id
      {
        resource-id: resource-id,
        extension-url: extension-url,
        extension-value-hash: extension-value-hash,
        extension-type: extension-type
      })
    (var-set extension-counter extension-id)
    (ok extension-id)))

(define-public (validate-resource
    (resource-id uint)
    (is-valid bool)
    (errors (list 10 (string-ascii 100))))
  (let ((validation-id (+ (var-get validation-counter) u1)))
    (map-set validation-results validation-id
      {
        resource-id: resource-id,
        validator: tx-sender,
        is-valid: is-valid,
        validation-errors: errors,
        validated-at: stacks-block-time
      })
    (var-set validation-counter validation-id)
    (ok validation-id)))

(define-public (update-resource
    (resource-id uint)
    (new-hash (buff 64)))
  (let ((resource (unwrap! (map-get? fhir-resources resource-id) ERR-RESOURCE-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner resource)) ERR-NOT-AUTHORIZED)
    (ok (map-set fhir-resources resource-id
      (merge resource {
        resource-hash: new-hash,
        last-updated: stacks-block-time
      })))))

(define-public (verify-mapping
    (source-system (string-ascii 50))
    (external-id (string-ascii 100)))
  (let ((mapping (unwrap! (map-get? resource-mappings { source-system: source-system, external-id: external-id }) ERR-RESOURCE-NOT-FOUND)))
    (ok (map-set resource-mappings { source-system: source-system, external-id: external-id }
      (merge mapping { is-verified: true })))))

(define-read-only (get-fhir-resource (resource-id uint))
  (ok (map-get? fhir-resources resource-id)))

(define-read-only (get-resource-mapping (source-system (string-ascii 50)) (external-id (string-ascii 100)))
  (ok (map-get? resource-mappings { source-system: source-system, external-id: external-id })))

(define-read-only (get-extension (extension-id uint))
  (ok (map-get? fhir-extensions extension-id)))

(define-read-only (get-validation-result (validation-id uint))
  (ok (map-get? validation-results validation-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-resource-id (resource-id uint))
  (ok (int-to-ascii resource-id)))

(define-read-only (parse-resource-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
