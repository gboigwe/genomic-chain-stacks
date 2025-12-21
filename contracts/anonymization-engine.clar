;; anonymization-engine.clar - Clarity 4
;; De-identification of genomic data

(define-constant ERR-NOT-AUTHORIZED (err u100))

(define-data-var anonymization-counter uint u0)

(define-map anonymized-datasets
  { dataset-id: uint }
  {
    original-owner: principal,
    anonymized-hash: (buff 32),
    anonymization-method: (string-ascii 50),
    created-at: uint,
    is-reversible: bool
  }
)

(define-public (anonymize-data
    (original-hash (buff 32))
    (anonymized-hash (buff 32))
    (method (string-ascii 50))
    (is-reversible bool))
  (let
    ((new-id (+ (var-get anonymization-counter) u1)))
    (map-set anonymized-datasets { dataset-id: new-id }
      {
        original-owner: tx-sender,
        anonymized-hash: anonymized-hash,
        anonymization-method: method,
        created-at: stacks-block-time,
        is-reversible: is-reversible
      })
    (var-set anonymization-counter new-id)
    (ok new-id)))

;; Clarity 4 features
(define-read-only (validate-owner (owner principal))
  (principal-destruct? owner))

(define-read-only (format-id (dataset-id uint))
  (ok (int-to-ascii dataset-id)))

(define-read-only (get-dataset (dataset-id uint))
  (ok (map-get? anonymized-datasets { dataset-id: dataset-id })))
