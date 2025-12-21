;; vaccination-record - Clarity 4
;; Vaccination history and verification

(define-constant ERR-RECORD-NOT-FOUND (err u100))
(define-data-var record-counter uint u0)

(define-map vaccination-records { record-id: uint }
  { patient: principal, provider: principal, vaccine-name: (string-ascii 100), administered-at: uint, lot-number: (string-ascii 50), next-dose: (optional uint) })

(define-public (record-vaccination (patient principal) (vaccine-name (string-ascii 100)) (lot-number (string-ascii 50)) (next-dose (optional uint)))
  (let ((new-id (+ (var-get record-counter) u1)))
    (map-set vaccination-records { record-id: new-id }
      { patient: patient, provider: tx-sender, vaccine-name: vaccine-name, administered-at: stacks-block-time, lot-number: lot-number, next-dose: next-dose })
    (var-set record-counter new-id)
    (ok new-id)))

(define-read-only (get-record (record-id uint))
  (ok (map-get? vaccination-records { record-id: record-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-provider (provider principal)) (principal-destruct? provider))

;; Clarity 4: int-to-ascii
(define-read-only (format-record-id (record-id uint)) (ok (int-to-ascii record-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-record-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
