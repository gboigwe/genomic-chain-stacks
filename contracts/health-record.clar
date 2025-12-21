;; health-record - Clarity 4
;; Electronic health records on blockchain

(define-constant ERR-RECORD-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-RECORD (err u102))

(define-map health-records uint
  {
    patient: principal,
    provider: principal,
    record-type: (string-ascii 50),
    data-hash: (buff 64),
    created-at: uint,
    is-verified: bool,
    confidentiality-level: (string-ascii 20),
    access-restrictions: (list 10 (string-ascii 50))
  }
)

(define-map record-amendments uint
  {
    original-record-id: uint,
    amendment-data-hash: (buff 64),
    amended-by: principal,
    amendment-reason: (string-utf8 300),
    amended-at: uint,
    approved: bool
  }
)

(define-map record-access-log uint
  {
    record-id: uint,
    accessed-by: principal,
    access-reason: (string-utf8 200),
    accessed-at: uint,
    access-type: (string-ascii 20)
  }
)

(define-map record-sharing uint
  {
    record-id: uint,
    shared-with: principal,
    shared-by: principal,
    sharing-purpose: (string-utf8 300),
    expiration: uint,
    is-active: bool
  }
)

(define-map record-annotations uint
  {
    record-id: uint,
    annotator: principal,
    annotation-text: (string-utf8 500),
    annotation-type: (string-ascii 50),
    created-at: uint
  }
)

(define-map emergency-access-grants uint
  {
    patient: principal,
    emergency-contact: principal,
    access-level: (string-ascii 20),
    granted-at: uint,
    expires-at: (optional uint),
    is-active: bool
  }
)

(define-data-var record-counter uint u0)
(define-data-var amendment-counter uint u0)
(define-data-var access-log-counter uint u0)
(define-data-var sharing-counter uint u0)
(define-data-var annotation-counter uint u0)
(define-data-var emergency-grant-counter uint u0)

(define-public (create-record
    (patient principal)
    (provider principal)
    (record-type (string-ascii 50))
    (data-hash (buff 64))
    (confidentiality-level (string-ascii 20))
    (access-restrictions (list 10 (string-ascii 50))))
  (let ((record-id (+ (var-get record-counter) u1)))
    (map-set health-records record-id
      {
        patient: patient,
        provider: provider,
        record-type: record-type,
        data-hash: data-hash,
        created-at: stacks-block-time,
        is-verified: false,
        confidentiality-level: confidentiality-level,
        access-restrictions: access-restrictions
      })
    (var-set record-counter record-id)
    (ok record-id)))

(define-public (verify-record (record-id uint))
  (let ((record (unwrap! (map-get? health-records record-id) ERR-RECORD-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get provider record)) ERR-NOT-AUTHORIZED)
    (ok (map-set health-records record-id
      (merge record { is-verified: true })))))

(define-public (amend-record
    (original-record-id uint)
    (amendment-data-hash (buff 64))
    (amendment-reason (string-utf8 300)))
  (let ((amendment-id (+ (var-get amendment-counter) u1)))
    (asserts! (is-some (map-get? health-records original-record-id)) ERR-RECORD-NOT-FOUND)
    (map-set record-amendments amendment-id
      {
        original-record-id: original-record-id,
        amendment-data-hash: amendment-data-hash,
        amended-by: tx-sender,
        amendment-reason: amendment-reason,
        amended-at: stacks-block-time,
        approved: false
      })
    (var-set amendment-counter amendment-id)
    (ok amendment-id)))

(define-public (log-record-access
    (record-id uint)
    (access-reason (string-utf8 200))
    (access-type (string-ascii 20)))
  (let ((log-id (+ (var-get access-log-counter) u1)))
    (asserts! (is-some (map-get? health-records record-id)) ERR-RECORD-NOT-FOUND)
    (map-set record-access-log log-id
      {
        record-id: record-id,
        accessed-by: tx-sender,
        access-reason: access-reason,
        accessed-at: stacks-block-time,
        access-type: access-type
      })
    (var-set access-log-counter log-id)
    (ok log-id)))

(define-public (share-record
    (record-id uint)
    (shared-with principal)
    (sharing-purpose (string-utf8 300))
    (expiration uint))
  (let ((sharing-id (+ (var-get sharing-counter) u1))
        (record (unwrap! (map-get? health-records record-id) ERR-RECORD-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get patient record)) ERR-NOT-AUTHORIZED)
    (map-set record-sharing sharing-id
      {
        record-id: record-id,
        shared-with: shared-with,
        shared-by: tx-sender,
        sharing-purpose: sharing-purpose,
        expiration: expiration,
        is-active: true
      })
    (var-set sharing-counter sharing-id)
    (ok sharing-id)))

(define-public (annotate-record
    (record-id uint)
    (annotation-text (string-utf8 500))
    (annotation-type (string-ascii 50)))
  (let ((annotation-id (+ (var-get annotation-counter) u1)))
    (asserts! (is-some (map-get? health-records record-id)) ERR-RECORD-NOT-FOUND)
    (map-set record-annotations annotation-id
      {
        record-id: record-id,
        annotator: tx-sender,
        annotation-text: annotation-text,
        annotation-type: annotation-type,
        created-at: stacks-block-time
      })
    (var-set annotation-counter annotation-id)
    (ok annotation-id)))

(define-public (grant-emergency-access
    (emergency-contact principal)
    (access-level (string-ascii 20))
    (expires-at (optional uint)))
  (let ((grant-id (+ (var-get emergency-grant-counter) u1)))
    (map-set emergency-access-grants grant-id
      {
        patient: tx-sender,
        emergency-contact: emergency-contact,
        access-level: access-level,
        granted-at: stacks-block-time,
        expires-at: expires-at,
        is-active: true
      })
    (var-set emergency-grant-counter grant-id)
    (ok grant-id)))

(define-read-only (get-record (record-id uint))
  (ok (map-get? health-records record-id)))

(define-read-only (get-amendment (amendment-id uint))
  (ok (map-get? record-amendments amendment-id)))

(define-read-only (get-access-log (log-id uint))
  (ok (map-get? record-access-log log-id)))

(define-read-only (get-sharing (sharing-id uint))
  (ok (map-get? record-sharing sharing-id)))

(define-read-only (get-annotation (annotation-id uint))
  (ok (map-get? record-annotations annotation-id)))

(define-read-only (get-emergency-grant (grant-id uint))
  (ok (map-get? emergency-access-grants grant-id)))

(define-read-only (validate-patient (patient principal))
  (principal-destruct? patient))

(define-read-only (format-record-id (record-id uint))
  (ok (int-to-ascii record-id)))

(define-read-only (parse-record-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
