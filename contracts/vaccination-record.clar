;; vaccination-record.clar - Clarity 4
;; Immunization records management

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-RECORD-NOT-FOUND (err u101))

(define-data-var record-counter uint u0)

(define-map vaccination-records
  { record-id: uint }
  {
    patient: principal,
    vaccine-name: (string-ascii 100),
    manufacturer: (string-ascii 100),
    lot-number: (string-ascii 50),
    administered-by: principal,
    administered-at: uint,
    dose-number: uint,
    next-dose-due: (optional uint),
    site: (string-ascii 50),
    is-verified: bool
  }
)

(define-public (record-vaccination
    (patient principal)
    (vaccine-name (string-ascii 100))
    (manufacturer (string-ascii 100))
    (lot-number (string-ascii 50))
    (dose-number uint)
    (next-dose-due (optional uint))
    (site (string-ascii 50)))
  (let
    ((new-id (+ (var-get record-counter) u1)))
    (map-set vaccination-records { record-id: new-id }
      {
        patient: patient,
        vaccine-name: vaccine-name,
        manufacturer: manufacturer,
        lot-number: lot-number,
        administered-by: tx-sender,
        administered-at: stacks-block-time,
        dose-number: dose-number,
        next-dose-due: next-dose-due,
        site: site,
        is-verified: false
      })
    (var-set record-counter new-id)
    (ok new-id)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-patient (patient principal))
  (principal-destruct? patient))

;; Clarity 4: int-to-ascii
(define-read-only (format-record-id (record-id uint))
  (ok (int-to-ascii record-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-record-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-vaccination-record (record-id uint))
  (ok (map-get? vaccination-records { record-id: record-id })))
