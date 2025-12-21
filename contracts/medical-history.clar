;; medical-history.clar - Clarity 4
;; Patient medical history tracking

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ENTRY-NOT-FOUND (err u101))

(define-data-var entry-counter uint u0)

(define-map history-entries
  { patient: principal, entry-id: uint }
  {
    condition: (string-ascii 100),
    diagnosis-date: uint,
    severity: uint,
    status: (string-ascii 20),
    notes: (string-utf8 256),
    recorded-by: principal,
    recorded-at: uint
  }
)

(define-public (add-history-entry
    (condition (string-ascii 100))
    (diagnosis-date uint)
    (severity uint)
    (status (string-ascii 20))
    (notes (string-utf8 256))
    (provider principal))
  (let
    ((new-id (+ (var-get entry-counter) u1)))
    (map-set history-entries { patient: tx-sender, entry-id: new-id }
      {
        condition: condition,
        diagnosis-date: diagnosis-date,
        severity: severity,
        status: status,
        notes: notes,
        recorded-by: provider,
        recorded-at: stacks-block-time
      })
    (var-set entry-counter new-id)
    (ok new-id)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-patient (patient principal))
  (principal-destruct? patient))

;; Clarity 4: int-to-utf8
(define-read-only (format-entry-id (entry-id uint))
  (ok (int-to-utf8 entry-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-entry-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-history-entry (patient principal) (entry-id uint))
  (ok (map-get? history-entries { patient: patient, entry-id: entry-id })))
