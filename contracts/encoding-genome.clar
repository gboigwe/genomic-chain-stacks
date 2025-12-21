;; encoding-genome - Clarity 4
;; Genomic data encoding and decoding utilities

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-FORMAT (err u101))
(define-constant ERR-ENCODING-NOT-FOUND (err u102))
(define-constant ERR-INVALID-SEQUENCE (err u103))

(define-map sequence-encodings uint
  {
    sequence-hash: (buff 64),
    encoding-type: (string-ascii 50),
    encoded-data: (buff 256),
    compression-ratio: uint,
    encoded-by: principal,
    encoded-at: uint,
    is-validated: bool
  }
)

(define-map encoding-methods (string-ascii 50)
  {
    method-name: (string-utf8 100),
    compression-level: uint,
    accuracy: uint,
    use-count: uint,
    is-active: bool
  }
)

(define-map quality-scores uint
  {
    sequence-id: uint,
    quality-string: (buff 128),
    average-quality: uint,
    min-quality: uint,
    max-quality: uint
  }
)

(define-map sequence-metadata uint
  {
    length: uint,
    gc-content: uint,
    n-content: uint,
    ambiguous-bases: uint,
    format: (string-ascii 20)
  }
)

(define-data-var encoding-counter uint u0)
(define-data-var quality-counter uint u0)
(define-data-var default-compression uint u75)

(define-public (encode-sequence
    (sequence-hash (buff 64))
    (encoding-type (string-ascii 50))
    (encoded-data (buff 256))
    (compression-ratio uint))
  (let ((encoding-id (+ (var-get encoding-counter) u1)))
    (map-set sequence-encodings encoding-id
      {
        sequence-hash: sequence-hash,
        encoding-type: encoding-type,
        encoded-data: encoded-data,
        compression-ratio: compression-ratio,
        encoded-by: tx-sender,
        encoded-at: stacks-block-time,
        is-validated: false
      })
    (var-set encoding-counter encoding-id)
    (ok encoding-id)))

(define-public (register-encoding-method
    (method-id (string-ascii 50))
    (method-name (string-utf8 100))
    (compression-level uint)
    (accuracy uint))
  (ok (map-set encoding-methods method-id
    {
      method-name: method-name,
      compression-level: compression-level,
      accuracy: accuracy,
      use-count: u0,
      is-active: true
    })))

(define-public (store-quality-scores
    (sequence-id uint)
    (quality-string (buff 128))
    (average-quality uint)
    (min-quality uint)
    (max-quality uint))
  (let ((quality-id (+ (var-get quality-counter) u1)))
    (map-set quality-scores quality-id
      {
        sequence-id: sequence-id,
        quality-string: quality-string,
        average-quality: average-quality,
        min-quality: min-quality,
        max-quality: max-quality
      })
    (var-set quality-counter quality-id)
    (ok quality-id)))

(define-public (validate-encoding (encoding-id uint))
  (let ((encoding (unwrap! (map-get? sequence-encodings encoding-id) ERR-ENCODING-NOT-FOUND)))
    (ok (map-set sequence-encodings encoding-id
      (merge encoding { is-validated: true })))))

(define-public (store-sequence-metadata
    (sequence-id uint)
    (length uint)
    (gc-content uint)
    (n-content uint)
    (ambiguous-bases uint)
    (format (string-ascii 20)))
  (ok (map-set sequence-metadata sequence-id
    {
      length: length,
      gc-content: gc-content,
      n-content: n-content,
      ambiguous-bases: ambiguous-bases,
      format: format
    })))

(define-public (increment-method-usage (method-id (string-ascii 50)))
  (let ((method (unwrap! (map-get? encoding-methods method-id) ERR-INVALID-FORMAT)))
    (ok (map-set encoding-methods method-id
      (merge method { use-count: (+ (get use-count method) u1) })))))

(define-read-only (get-encoding (encoding-id uint))
  (ok (map-get? sequence-encodings encoding-id)))

(define-read-only (get-encoding-method (method-id (string-ascii 50)))
  (ok (map-get? encoding-methods method-id)))

(define-read-only (get-quality-scores (quality-id uint))
  (ok (map-get? quality-scores quality-id)))

(define-read-only (get-sequence-metadata (sequence-id uint))
  (ok (map-get? sequence-metadata sequence-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-encoding-id (encoding-id uint))
  (ok (int-to-ascii encoding-id)))

(define-read-only (parse-encoding-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
