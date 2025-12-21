;; health-record - Clarity 4
;; Electronic health records on blockchain

(define-constant ERR-RECORD-NOT-FOUND (err u100))
(define-data-var record-counter uint u0)

(define-map health-records { record-id: uint }
  { patient: principal, provider: principal, record-type: (string-ascii 50), data-hash: (buff 64), created-at: uint, is-verified: bool })

(define-public (create-record (provider principal) (record-type (string-ascii 50)) (data-hash (buff 64)))
  (let ((new-id (+ (var-get record-counter) u1)))
    (map-set health-records { record-id: new-id }
      { patient: tx-sender, provider: provider, record-type: record-type, data-hash: data-hash, created-at: stacks-block-time, is-verified: false })
    (var-set record-counter new-id)
    (ok new-id)))

(define-read-only (get-record (record-id uint))
  (ok (map-get? health-records { record-id: record-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-patient (patient principal)) (principal-destruct? patient))

;; Clarity 4: int-to-ascii
(define-read-only (format-record-id (record-id uint)) (ok (int-to-ascii record-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-record-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
