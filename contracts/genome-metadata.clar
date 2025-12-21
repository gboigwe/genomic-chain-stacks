;; genome-metadata - Clarity 4
;; Comprehensive metadata storage and management for genomic datasets

(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-QUALITY (err u103))

(define-map genomic-metadata uint
  {
    owner: principal,
    sample-type: (string-ascii 50),
    sequencing-method: (string-ascii 50),
    quality-score: uint,
    genome-length: uint,
    created-at: uint,
    last-updated: uint,
    is-published: bool
  }
)

(define-map metadata-annotations uint
  {
    annotation-type: (string-ascii 50),
    annotation-data: (string-utf8 500),
    annotated-by: principal,
    annotated-at: uint,
    confidence-score: uint
  }
)

(define-map dataset-provenance uint
  {
    data-id: uint,
    source-institution: (string-utf8 200),
    collection-date: uint,
    processing-pipeline: (string-ascii 100),
    reference-genome: (string-ascii 50)
  }
)

(define-map quality-metrics uint
  {
    data-id: uint,
    coverage-depth: uint,
    base-quality: uint,
    mapping-quality: uint,
    duplicate-rate: uint,
    validated: bool
  }
)

(define-data-var metadata-counter uint u0)
(define-data-var annotation-counter uint u0)
(define-data-var min-quality-threshold uint u70)

(define-public (store-metadata
    (sample-type (string-ascii 50))
    (sequencing-method (string-ascii 50))
    (quality-score uint)
    (genome-length uint))
  (let ((metadata-id (+ (var-get metadata-counter) u1)))
    (asserts! (>= quality-score (var-get min-quality-threshold)) ERR-INVALID-QUALITY)
    (map-set genomic-metadata metadata-id
      {
        owner: tx-sender,
        sample-type: sample-type,
        sequencing-method: sequencing-method,
        quality-score: quality-score,
        genome-length: genome-length,
        created-at: stacks-block-time,
        last-updated: stacks-block-time,
        is-published: false
      })
    (var-set metadata-counter metadata-id)
    (ok metadata-id)))

(define-public (update-metadata
    (metadata-id uint)
    (new-quality-score uint)
    (is-published bool))
  (let ((metadata (unwrap! (map-get? genomic-metadata metadata-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner metadata)) ERR-NOT-AUTHORIZED)
    (ok (map-set genomic-metadata metadata-id
      (merge metadata {
        quality-score: new-quality-score,
        last-updated: stacks-block-time,
        is-published: is-published
      })))))

(define-public (add-annotation
    (data-id uint)
    (annotation-type (string-ascii 50))
    (annotation-data (string-utf8 500))
    (confidence-score uint))
  (let ((annotation-id (+ (var-get annotation-counter) u1))
        (metadata (unwrap! (map-get? genomic-metadata data-id) ERR-NOT-FOUND)))
    (map-set metadata-annotations annotation-id
      {
        annotation-type: annotation-type,
        annotation-data: annotation-data,
        annotated-by: tx-sender,
        annotated-at: stacks-block-time,
        confidence-score: confidence-score
      })
    (var-set annotation-counter annotation-id)
    (ok annotation-id)))

(define-public (record-provenance
    (data-id uint)
    (source-institution (string-utf8 200))
    (collection-date uint)
    (processing-pipeline (string-ascii 100))
    (reference-genome (string-ascii 50)))
  (let ((metadata (unwrap! (map-get? genomic-metadata data-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner metadata)) ERR-NOT-AUTHORIZED)
    (ok (map-set dataset-provenance data-id
      {
        data-id: data-id,
        source-institution: source-institution,
        collection-date: collection-date,
        processing-pipeline: processing-pipeline,
        reference-genome: reference-genome
      }))))

(define-public (record-quality-metrics
    (data-id uint)
    (coverage-depth uint)
    (base-quality uint)
    (mapping-quality uint)
    (duplicate-rate uint))
  (let ((metadata (unwrap! (map-get? genomic-metadata data-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner metadata)) ERR-NOT-AUTHORIZED)
    (ok (map-set quality-metrics data-id
      {
        data-id: data-id,
        coverage-depth: coverage-depth,
        base-quality: base-quality,
        mapping-quality: mapping-quality,
        duplicate-rate: duplicate-rate,
        validated: false
      }))))

(define-public (validate-quality-metrics (data-id uint))
  (let ((metrics (unwrap! (map-get? quality-metrics data-id) ERR-NOT-FOUND)))
    (ok (map-set quality-metrics data-id
      (merge metrics { validated: true })))))

(define-read-only (get-metadata (data-id uint))
  (ok (map-get? genomic-metadata data-id)))

(define-read-only (get-annotation (annotation-id uint))
  (ok (map-get? metadata-annotations annotation-id)))

(define-read-only (get-provenance (data-id uint))
  (ok (map-get? dataset-provenance data-id)))

(define-read-only (get-quality-metrics (data-id uint))
  (ok (map-get? quality-metrics data-id)))

(define-read-only (validate-owner (owner principal))
  (principal-destruct? owner))

(define-read-only (format-data-id (data-id uint))
  (ok (int-to-ascii data-id)))

(define-read-only (parse-data-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
