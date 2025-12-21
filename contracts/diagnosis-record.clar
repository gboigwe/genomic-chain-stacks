;; diagnosis-record - Clarity 4
;; Medical diagnosis records and tracking

(define-constant ERR-DIAGNOSIS-NOT-FOUND (err u100))
(define-data-var diagnosis-counter uint u0)

(define-map diagnoses { diagnosis-id: uint }
  { patient: principal, provider: principal, icd-code: (string-ascii 20), description: (string-utf8 200), diagnosed-at: uint, severity: (string-ascii 20) })

(define-public (record-diagnosis (patient principal) (icd-code (string-ascii 20)) (description (string-utf8 200)) (severity (string-ascii 20)))
  (let ((new-id (+ (var-get diagnosis-counter) u1)))
    (map-set diagnoses { diagnosis-id: new-id }
      { patient: patient, provider: tx-sender, icd-code: icd-code, description: description, diagnosed-at: stacks-block-time, severity: severity })
    (var-set diagnosis-counter new-id)
    (ok new-id)))

(define-read-only (get-diagnosis (diagnosis-id uint))
  (ok (map-get? diagnoses { diagnosis-id: diagnosis-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-provider (provider principal)) (principal-destruct? provider))

;; Clarity 4: int-to-ascii
(define-read-only (format-diagnosis-id (diagnosis-id uint)) (ok (int-to-ascii diagnosis-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-diagnosis-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
