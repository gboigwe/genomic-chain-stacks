;; mock-genome-data.clar - Clarity 4
;; Mock genomic data for testing

(define-data-var mock-counter uint u0)

(define-map mock-genomes
  { genome-id: uint }
  {
    mock-hash: (buff 32),
    mock-sequence: (string-ascii 100),
    created-at: uint
  }
)

(define-public (create-mock-genome
    (mock-hash (buff 32))
    (mock-sequence (string-ascii 100)))
  (let
    ((new-id (+ (var-get mock-counter) u1)))
    (map-set mock-genomes { genome-id: new-id }
      {
        mock-hash: mock-hash,
        mock-sequence: mock-sequence,
        created-at: stacks-block-time
      })
    (var-set mock-counter new-id)
    (ok new-id)))

;; Clarity 4 features
(define-read-only (format-genome-id (genome-id uint))
  (ok (int-to-ascii genome-id)))

(define-read-only (get-mock-genome (genome-id uint))
  (ok (map-get? mock-genomes { genome-id: genome-id })))
