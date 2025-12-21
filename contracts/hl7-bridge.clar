;; hl7-bridge - Clarity 4
;; HL7 FHIR message interoperability bridge

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-MESSAGE-NOT-FOUND (err u101))
(define-constant ERR-INVALID-FORMAT (err u102))
(define-constant ERR-ALREADY-PROCESSED (err u103))

(define-map hl7-messages uint
  {
    message-id: (string-ascii 100),
    message-type: (string-ascii 50),
    sender-system: (string-ascii 100),
    receiver-system: (string-ascii 100),
    patient-id: (string-ascii 50),
    data-hash: (buff 64),
    timestamp: uint,
    processed: bool,
    processing-status: (string-ascii 20)
  }
)

(define-map message-mappings { external-id: (string-ascii 100) }
  { internal-id: uint, mapped-at: uint }
)

(define-map system-endpoints (string-ascii 100)
  {
    endpoint-url: (string-utf8 256),
    api-key-hash: (buff 64),
    is-active: bool,
    last-sync: uint
  }
)

(define-map transformation-rules (string-ascii 50)
  {
    source-format: (string-ascii 50),
    target-format: (string-ascii 50),
    mapping-schema-hash: (buff 64),
    created-at: uint
  }
)

(define-data-var message-counter uint u0)

;; Register HL7 message
(define-public (register-hl7-message
    (message-id (string-ascii 100))
    (message-type (string-ascii 50))
    (sender-system (string-ascii 100))
    (receiver-system (string-ascii 100))
    (patient-id (string-ascii 50))
    (data-hash (buff 64)))
  (let ((internal-id (+ (var-get message-counter) u1)))
    (map-set hl7-messages internal-id
      {
        message-id: message-id,
        message-type: message-type,
        sender-system: sender-system,
        receiver-system: receiver-system,
        patient-id: patient-id,
        data-hash: data-hash,
        timestamp: stacks-block-time,
        processed: false,
        processing-status: "pending"
      })
    (map-set message-mappings { external-id: message-id }
      { internal-id: internal-id, mapped-at: stacks-block-time })
    (var-set message-counter internal-id)
    (ok internal-id)))

;; Mark message as processed
(define-public (mark-message-processed (internal-id uint) (status (string-ascii 20)))
  (let ((message (unwrap! (map-get? hl7-messages internal-id) ERR-MESSAGE-NOT-FOUND)))
    (asserts! (not (get processed message)) ERR-ALREADY-PROCESSED)
    (ok (map-set hl7-messages internal-id
      (merge message { processed: true, processing-status: status })))))

;; Register external system endpoint
(define-public (register-endpoint
    (system-id (string-ascii 100))
    (endpoint-url (string-utf8 256))
    (api-key-hash (buff 64)))
  (ok (map-set system-endpoints system-id
    {
      endpoint-url: endpoint-url,
      api-key-hash: api-key-hash,
      is-active: true,
      last-sync: stacks-block-time
    })))

;; Create transformation rule
(define-public (create-transformation-rule
    (rule-id (string-ascii 50))
    (source-format (string-ascii 50))
    (target-format (string-ascii 50))
    (mapping-schema-hash (buff 64)))
  (ok (map-set transformation-rules rule-id
    {
      source-format: source-format,
      target-format: target-format,
      mapping-schema-hash: mapping-schema-hash,
      created-at: stacks-block-time
    })))

;; Update endpoint sync timestamp
(define-public (update-endpoint-sync (system-id (string-ascii 100)))
  (let ((endpoint (unwrap! (map-get? system-endpoints system-id) ERR-MESSAGE-NOT-FOUND)))
    (ok (map-set system-endpoints system-id
      (merge endpoint { last-sync: stacks-block-time })))))

;; Deactivate endpoint
(define-public (deactivate-endpoint (system-id (string-ascii 100)))
  (let ((endpoint (unwrap! (map-get? system-endpoints system-id) ERR-MESSAGE-NOT-FOUND)))
    (ok (map-set system-endpoints system-id
      (merge endpoint { is-active: false })))))

;; Read-only functions
(define-read-only (get-message (internal-id uint))
  (ok (map-get? hl7-messages internal-id)))

(define-read-only (get-message-by-external-id (external-id (string-ascii 100)))
  (match (map-get? message-mappings { external-id: external-id })
    mapping (ok (map-get? hl7-messages (get internal-id mapping)))
    (ok none)))

(define-read-only (get-endpoint (system-id (string-ascii 100)))
  (ok (map-get? system-endpoints system-id)))

(define-read-only (get-transformation-rule (rule-id (string-ascii 50)))
  (ok (map-get? transformation-rules rule-id)))

(define-read-only (get-total-messages)
  (ok (var-get message-counter)))

(define-read-only (is-message-processed (internal-id uint))
  (match (map-get? hl7-messages internal-id)
    message (ok (get processed message))
    (ok false)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

;; Clarity 4: int-to-ascii
(define-read-only (format-message-id (internal-id uint))
  (ok (int-to-ascii internal-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-message-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
