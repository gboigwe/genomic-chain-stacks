;; health-record.clar - Clarity 4
;; Electronic health records (EHR) management

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-RECORD-NOT-FOUND (err u101))
(define-constant ERR-RECORD-EXISTS (err u102))

(define-data-var record-counter uint u0)

(define-map health-records
  { patient: principal, record-id: uint }
  {
    encrypted-data: (buff 256),
    record-type: (string-ascii 50),
    provider: principal,
    created-at: uint,
    updated-at: uint,
    is-verified: bool,
    access-level: uint
  }
)

(define-public (create-record
    (encrypted-data (buff 256))
    (record-type (string-ascii 50))
    (provider principal))
  (let
    ((new-id (+ (var-get record-counter) u1)))
    (asserts! (is-none (map-get? health-records { patient: tx-sender, record-id: new-id })) ERR-RECORD-EXISTS)
    (map-set health-records { patient: tx-sender, record-id: new-id }
      {
        encrypted-data: encrypted-data,
        record-type: record-type,
        provider: provider,
        created-at: stacks-block-time,
        updated-at: stacks-block-time,
        is-verified: false,
        access-level: u1
      })
    (var-set record-counter new-id)
    (ok new-id)))

(define-public (update-record
    (record-id uint)
    (encrypted-data (buff 256)))
  (let
    ((record (unwrap! (map-get? health-records { patient: tx-sender, record-id: record-id }) ERR-RECORD-NOT-FOUND)))
    (map-set health-records { patient: tx-sender, record-id: record-id }
      (merge record { encrypted-data: encrypted-data, updated-at: stacks-block-time }))
    (ok true)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-patient (patient principal))
  (principal-destruct? patient))

;; Clarity 4: int-to-ascii
(define-read-only (format-record-id (record-id uint))
  (ok (int-to-ascii record-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-record-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-height)
  (ok burn-block-height))

(define-read-only (get-record (patient principal) (record-id uint))
  (ok (map-get? health-records { patient: patient, record-id: record-id })))
