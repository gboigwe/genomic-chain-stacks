;; string-genome - Clarity 4
;; String utility functions for genomic data processing

(define-constant ERR-INVALID-INPUT (err u100))
(define-constant ERR-OUT-OF-BOUNDS (err u101))

(define-map sequence-metadata (buff 64)
  {
    sequence-name: (string-utf8 100),
    length: uint,
    gc-content: uint,
    quality-score: uint,
    created-at: uint
  }
)

(define-map sequence-annotations (buff 64)
  {
    annotation-type: (string-ascii 50),
    start-position: uint,
    end-position: uint,
    description: (string-utf8 500),
    annotated-at: uint
  }
)

(define-map sequence-comparisons uint
  {
    sequence-a: (buff 64),
    sequence-b: (buff 64),
    similarity-score: uint,
    alignment-length: uint,
    compared-at: uint,
    comparison-method: (string-ascii 50)
  }
)

(define-map codon-translations uint
  {
    codon-sequence: (string-ascii 3),
    amino-acid: (string-ascii 3),
    start-codon: bool,
    stop-codon: bool
  }
)

(define-data-var comparison-counter uint u0)
(define-data-var translation-counter uint u0)

(define-public (register-sequence
    (sequence-hash (buff 64))
    (sequence-name (string-utf8 100))
    (length uint)
    (gc-content uint)
    (quality-score uint))
  (begin
    (asserts! (> length u0) ERR-INVALID-INPUT)
    (asserts! (<= gc-content u100) ERR-INVALID-INPUT)
    (asserts! (<= quality-score u100) ERR-INVALID-INPUT)
    (ok (map-set sequence-metadata sequence-hash
      {
        sequence-name: sequence-name,
        length: length,
        gc-content: gc-content,
        quality-score: quality-score,
        created-at: stacks-block-time
      }))))

(define-public (add-annotation
    (sequence-hash (buff 64))
    (annotation-type (string-ascii 50))
    (start-position uint)
    (end-position uint)
    (description (string-utf8 500)))
  (let ((metadata (unwrap! (map-get? sequence-metadata sequence-hash) ERR-INVALID-INPUT)))
    (asserts! (< start-position end-position) ERR-INVALID-INPUT)
    (asserts! (<= end-position (get length metadata)) ERR-OUT-OF-BOUNDS)
    (ok (map-set sequence-annotations sequence-hash
      {
        annotation-type: annotation-type,
        start-position: start-position,
        end-position: end-position,
        description: description,
        annotated-at: stacks-block-time
      }))))

(define-public (compare-sequences
    (sequence-a (buff 64))
    (sequence-b (buff 64))
    (similarity-score uint)
    (alignment-length uint)
    (comparison-method (string-ascii 50)))
  (let ((comparison-id (+ (var-get comparison-counter) u1)))
    (asserts! (<= similarity-score u100) ERR-INVALID-INPUT)
    (map-set sequence-comparisons comparison-id
      {
        sequence-a: sequence-a,
        sequence-b: sequence-b,
        similarity-score: similarity-score,
        alignment-length: alignment-length,
        compared-at: stacks-block-time,
        comparison-method: comparison-method
      })
    (var-set comparison-counter comparison-id)
    (ok comparison-id)))

(define-public (register-codon
    (codon-sequence (string-ascii 3))
    (amino-acid (string-ascii 3))
    (start-codon bool)
    (stop-codon bool))
  (let ((translation-id (+ (var-get translation-counter) u1)))
    (map-set codon-translations translation-id
      {
        codon-sequence: codon-sequence,
        amino-acid: amino-acid,
        start-codon: start-codon,
        stop-codon: stop-codon
      })
    (var-set translation-counter translation-id)
    (ok translation-id)))

(define-read-only (get-sequence-metadata (sequence-hash (buff 64)))
  (ok (map-get? sequence-metadata sequence-hash)))

(define-read-only (get-sequence-annotation (sequence-hash (buff 64)))
  (ok (map-get? sequence-annotations sequence-hash)))

(define-read-only (get-comparison (comparison-id uint))
  (ok (map-get? sequence-comparisons comparison-id)))

(define-read-only (get-codon-translation (translation-id uint))
  (ok (map-get? codon-translations translation-id)))

(define-read-only (calculate-gc-percentage (g-count uint) (c-count uint) (total-length uint))
  (ok (if (> total-length u0)
      (/ (* (+ g-count c-count) u100) total-length)
      u0)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-comparison-id (comparison-id uint))
  (ok (int-to-ascii comparison-id)))

(define-read-only (parse-comparison-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
