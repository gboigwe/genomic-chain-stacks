;; genome-registry - Clarity 4
;; Registry of all genomic records

(define-constant ERR-NOT-FOUND (err u101))
(define-data-var record-counter uint u0)

(define-map genomic-records { record-id: uint }
  { patient: principal, vault-ref: uint, data-type: (string-ascii 50), created-at: uint, is-verified: bool })

(define-public (register-record (vault-ref uint) (data-type (string-ascii 50)))
  (let ((new-id (+ (var-get record-counter) u1)))
    (map-set genomic-records { record-id: new-id }
      { patient: tx-sender, vault-ref: vault-ref, data-type: data-type, created-at: stacks-block-time, is-verified: false })
    (var-set record-counter new-id)
    (ok new-id)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-patient (patient principal)) (principal-destruct? patient))

;; Clarity 4: int-to-utf8
(define-read-only (format-record-id (record-id uint)) (ok (int-to-utf8 record-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-record-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))

(define-read-only (get-record (record-id uint)) (ok (map-get? genomic-records { record-id: record-id })))
