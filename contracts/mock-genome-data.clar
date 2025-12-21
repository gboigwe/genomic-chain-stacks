;; mock-genome-data - Clarity 4
;; Mock genomic data generator for testing and development

(define-constant ERR-INVALID-INDEX (err u100))

(define-data-var sample-counter uint u0)

(define-map mock-sequences uint
  {
    sequence-id: (string-ascii 50),
    sequence-hash: (buff 64),
    sequence-length: uint,
    gc-content: uint,
    chromosome: (string-ascii 10),
    start-position: uint,
    end-position: uint
  }
)

(define-map mock-variants uint
  {
    variant-id: (string-ascii 50),
    chromosome: (string-ascii 10),
    position: uint,
    reference-allele: (string-ascii 10),
    alternate-allele: (string-ascii 10),
    variant-type: (string-ascii 20),
    quality-score: uint
  }
)

(define-public (generate-mock-sequence
    (sequence-id (string-ascii 50))
    (sequence-hash (buff 64))
    (length uint)
    (gc-content uint)
    (chromosome (string-ascii 10))
    (start-pos uint))
  (let ((sample-id (+ (var-get sample-counter) u1)))
    (map-set mock-sequences sample-id
      {
        sequence-id: sequence-id,
        sequence-hash: sequence-hash,
        sequence-length: length,
        gc-content: gc-content,
        chromosome: chromosome,
        start-position: start-pos,
        end-position: (+ start-pos length)
      })
    (var-set sample-counter sample-id)
    (ok sample-id)))

(define-public (generate-mock-variant
    (variant-id (string-ascii 50))
    (chromosome (string-ascii 10))
    (position uint)
    (ref-allele (string-ascii 10))
    (alt-allele (string-ascii 10))
    (variant-type (string-ascii 20))
    (quality uint))
  (let ((variant-index (+ (var-get sample-counter) u1)))
    (map-set mock-variants variant-index
      {
        variant-id: variant-id,
        chromosome: chromosome,
        position: position,
        reference-allele: ref-allele,
        alternate-allele: alt-allele,
        variant-type: variant-type,
        quality-score: quality
      })
    (var-set sample-counter variant-index)
    (ok variant-index)))

(define-read-only (get-mock-sequence (index uint))
  (ok (map-get? mock-sequences index)))

(define-read-only (get-mock-variant (index uint))
  (ok (map-get? mock-variants index)))

(define-read-only (get-sample-count)
  (ok (var-get sample-counter)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-index (index uint))
  (ok (int-to-ascii index)))

(define-read-only (parse-index (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
