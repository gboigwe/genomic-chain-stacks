;; genome-registry.clar - Clarity 4
;; Registry of all genomic records with metadata

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-REGISTERED (err u101))
(define-constant ERR-NOT-FOUND (err u102))

(define-data-var record-counter uint u0)

;; Genomic record registry
(define-map genomic-records
  { record-id: uint }
  {
    patient: principal,
    vault-ref: uint,
    data-type: (string-ascii 50),
    created-at: uint,
    last-accessed: uint,
    access-count: uint,
    is-verified: bool,
    verifier: (optional principal)
  }
)

;; Register genomic record
(define-public (register-record
    (vault-ref uint)
    (data-type (string-ascii 50)))
  (let
    ((new-id (+ (var-get record-counter) u1)))
    (map-set genomic-records { record-id: new-id }
      {
        patient: tx-sender,
        vault-ref: vault-ref,
        data-type: data-type,
        created-at: stacks-block-time,
        last-accessed: stacks-block-time,
        access-count: u0,
        is-verified: false,
        verifier: none
      })
    (var-set record-counter new-id)
    (ok new-id)))

;; Verify record
(define-public (verify-record (record-id uint))
  (let
    ((record (unwrap! (map-get? genomic-records { record-id: record-id }) ERR-NOT-FOUND)))
    (map-set genomic-records { record-id: record-id }
      (merge record { is-verified: true, verifier: (some tx-sender) }))
    (ok true)))

;; Clarity 4 features
(define-read-only (validate-patient (patient principal))
  (principal-destruct? patient))

(define-read-only (format-record-id (record-id uint))
  (ok (int-to-utf8 record-id)))

(define-read-only (parse-record-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-record (record-id uint))
  (ok (map-get? genomic-records { record-id: record-id })))

(define-read-only (get-record-counter)
  (ok (var-get record-counter)))
