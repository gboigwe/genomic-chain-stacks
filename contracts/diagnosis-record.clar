;; diagnosis-record.clar - Clarity 4
;; Medical diagnosis records

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-DIAGNOSIS-NOT-FOUND (err u101))

(define-data-var diagnosis-counter uint u0)

(define-map diagnoses
  { diagnosis-id: uint }
  {
    patient: principal,
    provider: principal,
    icd10-code: (string-ascii 10),
    condition: (string-ascii 200),
    severity: uint,
    diagnosed-at: uint,
    notes: (string-utf8 500),
    is-confirmed: bool
  }
)

(define-public (record-diagnosis
    (patient principal)
    (icd10-code (string-ascii 10))
    (condition (string-ascii 200))
    (severity uint)
    (notes (string-utf8 500)))
  (let
    ((new-id (+ (var-get diagnosis-counter) u1)))
    (map-set diagnoses { diagnosis-id: new-id }
      {
        patient: patient,
        provider: tx-sender,
        icd10-code: icd10-code,
        condition: condition,
        severity: severity,
        diagnosed-at: stacks-block-time,
        notes: notes,
        is-confirmed: false
      })
    (var-set diagnosis-counter new-id)
    (ok new-id)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-patient (patient principal))
  (principal-destruct? patient))

;; Clarity 4: int-to-ascii
(define-read-only (format-diagnosis-id (diagnosis-id uint))
  (ok (int-to-ascii diagnosis-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-diagnosis-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-diagnosis (diagnosis-id uint))
  (ok (map-get? diagnoses { diagnosis-id: diagnosis-id })))
