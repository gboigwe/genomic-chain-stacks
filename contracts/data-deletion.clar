;; data-deletion - Clarity 4
;; Right to be forgotten and data deletion management

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-REQUEST-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-PROCESSED (err u102))

(define-map deletion-requests uint
  {
    requester: principal,
    data-type: (string-ascii 50),
    data-references: (list 10 uint),
    reason: (string-utf8 200),
    requested-at: uint,
    processed: bool,
    processed-at: (optional uint),
    verification-hash: (buff 64)
  }
)

(define-map data-retention-policies principal
  {
    retention-period: uint,
    auto-delete: bool,
    exceptions: (list 5 (string-ascii 50)),
    created-at: uint
  }
)

(define-map deletion-verifications uint
  {
    request-id: uint,
    verifier: principal,
    verification-proof: (buff 64),
    verified-at: uint,
    fully-deleted: bool
  }
)

(define-map deleted-data-hashes (buff 64)
  {
    original-owner: principal,
    deleted-at: uint,
    deletion-method: (string-ascii 50),
    permanent: bool
  }
)

(define-data-var request-counter uint u0)
(define-data-var verification-counter uint u0)
(define-data-var default-retention uint u157680000) ;; 5 years

(define-public (request-deletion
    (data-type (string-ascii 50))
    (data-references (list 10 uint))
    (reason (string-utf8 200))
    (verification-hash (buff 64)))
  (let ((request-id (+ (var-get request-counter) u1)))
    (map-set deletion-requests request-id
      {
        requester: tx-sender,
        data-type: data-type,
        data-references: data-references,
        reason: reason,
        requested-at: stacks-block-time,
        processed: false,
        processed-at: none,
        verification-hash: verification-hash
      })
    (var-set request-counter request-id)
    (ok request-id)))

(define-public (process-deletion (request-id uint))
  (let ((request (unwrap! (map-get? deletion-requests request-id) ERR-REQUEST-NOT-FOUND)))
    (asserts! (not (get processed request)) ERR-ALREADY-PROCESSED)
    (ok (map-set deletion-requests request-id
      (merge request {
        processed: true,
        processed-at: (some stacks-block-time)
      })))))

(define-public (verify-deletion
    (request-id uint)
    (verification-proof (buff 64))
    (fully-deleted bool))
  (let ((request (unwrap! (map-get? deletion-requests request-id) ERR-REQUEST-NOT-FOUND))
        (verification-id (+ (var-get verification-counter) u1)))
    (asserts! (get processed request) ERR-REQUEST-NOT-FOUND)
    (map-set deletion-verifications verification-id
      {
        request-id: request-id,
        verifier: tx-sender,
        verification-proof: verification-proof,
        verified-at: stacks-block-time,
        fully-deleted: fully-deleted
      })
    (var-set verification-counter verification-id)
    (ok verification-id)))

(define-public (set-retention-policy
    (retention-period uint)
    (auto-delete bool)
    (exceptions (list 5 (string-ascii 50))))
  (ok (map-set data-retention-policies tx-sender
    {
      retention-period: retention-period,
      auto-delete: auto-delete,
      exceptions: exceptions,
      created-at: stacks-block-time
    })))

(define-public (register-deleted-data
    (data-hash (buff 64))
    (deletion-method (string-ascii 50))
    (permanent bool))
  (ok (map-set deleted-data-hashes data-hash
    {
      original-owner: tx-sender,
      deleted-at: stacks-block-time,
      deletion-method: deletion-method,
      permanent: permanent
    })))

(define-read-only (get-deletion-request (request-id uint))
  (ok (map-get? deletion-requests request-id)))

(define-read-only (get-retention-policy (owner principal))
  (ok (map-get? data-retention-policies owner)))

(define-read-only (get-deletion-verification (verification-id uint))
  (ok (map-get? deletion-verifications verification-id)))

(define-read-only (is-data-deleted (data-hash (buff 64)))
  (ok (is-some (map-get? deleted-data-hashes data-hash))))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-request-id (request-id uint))
  (ok (int-to-ascii request-id)))

(define-read-only (parse-request-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
