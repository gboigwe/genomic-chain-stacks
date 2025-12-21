;; genome-registry - Clarity 4
;; Comprehensive registry of all genomic records with versioning and verification

(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-NOT-AUTHORIZED (err u102))
(define-constant ERR-ALREADY-VERIFIED (err u103))
(define-constant ERR-INVALID-STATUS (err u104))

(define-map genomic-records uint
  {
    patient: principal,
    vault-ref: uint,
    data-type: (string-ascii 50),
    data-hash: (buff 64),
    created-at: uint,
    last-updated: uint,
    is-verified: bool,
    verification-level: (string-ascii 20),
    status: (string-ascii 20)
  }
)

(define-map record-versions uint
  {
    record-id: uint,
    version-number: uint,
    data-hash: (buff 64),
    updated-by: principal,
    updated-at: uint,
    change-description: (string-utf8 200)
  }
)

(define-map record-verifications uint
  {
    record-id: uint,
    verified-by: principal,
    verification-method: (string-ascii 50),
    verified-at: uint,
    verification-proof: (buff 64)
  }
)

(define-map record-access-logs uint
  {
    record-id: uint,
    accessed-by: principal,
    access-type: (string-ascii 50),
    accessed-at: uint,
    purpose: (string-utf8 200)
  }
)

(define-data-var record-counter uint u0)
(define-data-var version-counter uint u0)
(define-data-var verification-counter uint u0)
(define-data-var access-log-counter uint u0)

(define-public (register-record
    (vault-ref uint)
    (data-type (string-ascii 50))
    (data-hash (buff 64)))
  (let ((record-id (+ (var-get record-counter) u1)))
    (map-set genomic-records record-id
      {
        patient: tx-sender,
        vault-ref: vault-ref,
        data-type: data-type,
        data-hash: data-hash,
        created-at: stacks-block-time,
        last-updated: stacks-block-time,
        is-verified: false,
        verification-level: "none",
        status: "active"
      })
    (var-set record-counter record-id)
    (ok record-id)))

(define-public (update-record
    (record-id uint)
    (new-data-hash (buff 64))
    (change-description (string-utf8 200)))
  (let ((record (unwrap! (map-get? genomic-records record-id) ERR-NOT-FOUND))
        (version-id (+ (var-get version-counter) u1)))
    (asserts! (is-eq tx-sender (get patient record)) ERR-NOT-AUTHORIZED)
    (map-set record-versions version-id
      {
        record-id: record-id,
        version-number: version-id,
        data-hash: new-data-hash,
        updated-by: tx-sender,
        updated-at: stacks-block-time,
        change-description: change-description
      })
    (map-set genomic-records record-id
      (merge record {
        data-hash: new-data-hash,
        last-updated: stacks-block-time
      }))
    (var-set version-counter version-id)
    (ok version-id)))

(define-public (verify-record
    (record-id uint)
    (verification-method (string-ascii 50))
    (verification-proof (buff 64))
    (verification-level (string-ascii 20)))
  (let ((record (unwrap! (map-get? genomic-records record-id) ERR-NOT-FOUND))
        (verification-id (+ (var-get verification-counter) u1)))
    (asserts! (not (get is-verified record)) ERR-ALREADY-VERIFIED)
    (map-set record-verifications verification-id
      {
        record-id: record-id,
        verified-by: tx-sender,
        verification-method: verification-method,
        verified-at: stacks-block-time,
        verification-proof: verification-proof
      })
    (map-set genomic-records record-id
      (merge record {
        is-verified: true,
        verification-level: verification-level
      }))
    (var-set verification-counter verification-id)
    (ok verification-id)))

(define-public (update-record-status
    (record-id uint)
    (new-status (string-ascii 20)))
  (let ((record (unwrap! (map-get? genomic-records record-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get patient record)) ERR-NOT-AUTHORIZED)
    (ok (map-set genomic-records record-id
      (merge record { status: new-status })))))

(define-public (log-record-access
    (record-id uint)
    (access-type (string-ascii 50))
    (purpose (string-utf8 200)))
  (let ((log-id (+ (var-get access-log-counter) u1))
        (record (unwrap! (map-get? genomic-records record-id) ERR-NOT-FOUND)))
    (map-set record-access-logs log-id
      {
        record-id: record-id,
        accessed-by: tx-sender,
        access-type: access-type,
        accessed-at: stacks-block-time,
        purpose: purpose
      })
    (var-set access-log-counter log-id)
    (ok log-id)))

(define-read-only (get-record (record-id uint))
  (ok (map-get? genomic-records record-id)))

(define-read-only (get-record-version (version-id uint))
  (ok (map-get? record-versions version-id)))

(define-read-only (get-verification (verification-id uint))
  (ok (map-get? record-verifications verification-id)))

(define-read-only (get-access-log (log-id uint))
  (ok (map-get? record-access-logs log-id)))

(define-read-only (validate-patient (patient principal))
  (principal-destruct? patient))

(define-read-only (format-record-id (record-id uint))
  (ok (int-to-ascii record-id)))

(define-read-only (parse-record-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
