;; emergency-access - Clarity 4
;; Emergency medical data access for critical situations

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-REQUEST-NOT-FOUND (err u101))
(define-constant ERR-NOT-EMERGENCY (err u102))
(define-constant ERR-ACCESS-EXPIRED (err u103))

(define-map emergency-requests uint
  {
    requester: principal,
    patient-id: (string-ascii 50),
    emergency-type: (string-ascii 50),
    justification: (string-utf8 200),
    requested-at: uint,
    approved: bool,
    approver: (optional principal),
    expires-at: uint
  }
)

(define-map emergency-responders principal
  {
    organization: (string-utf8 100),
    license-number: (string-ascii 50),
    specialization: (string-ascii 50),
    verified: bool,
    total-accesses: uint
  }
)

(define-map emergency-access-logs uint
  {
    request-id: uint,
    responder: principal,
    patient-id: (string-ascii 50),
    data-accessed: (string-ascii 100),
    access-timestamp: uint,
    audit-trail-hash: (buff 64)
  }
)

(define-map patient-emergency-contacts principal
  {
    primary-contact: principal,
    secondary-contact: (optional principal),
    allow-emergency-access: bool,
    restrictions: (string-utf8 200)
  }
)

(define-data-var request-counter uint u0)
(define-data-var access-log-counter uint u0)
(define-data-var emergency-window uint u3600) ;; 1 hour default

(define-public (register-responder
    (organization (string-utf8 100))
    (license-number (string-ascii 50))
    (specialization (string-ascii 50)))
  (ok (map-set emergency-responders tx-sender
    {
      organization: organization,
      license-number: license-number,
      specialization: specialization,
      verified: false,
      total-accesses: u0
    })))

(define-public (request-emergency-access
    (patient-id (string-ascii 50))
    (emergency-type (string-ascii 50))
    (justification (string-utf8 200)))
  (let ((request-id (+ (var-get request-counter) u1))
        (responder (unwrap! (map-get? emergency-responders tx-sender) ERR-NOT-AUTHORIZED)))
    (asserts! (get verified responder) ERR-NOT-AUTHORIZED)
    (map-set emergency-requests request-id
      {
        requester: tx-sender,
        patient-id: patient-id,
        emergency-type: emergency-type,
        justification: justification,
        requested-at: stacks-block-time,
        approved: false,
        approver: none,
        expires-at: (+ stacks-block-time (var-get emergency-window))
      })
    (var-set request-counter request-id)
    (ok request-id)))

(define-public (approve-emergency-access (request-id uint))
  (let ((request (unwrap! (map-get? emergency-requests request-id) ERR-REQUEST-NOT-FOUND)))
    (ok (map-set emergency-requests request-id
      (merge request {
        approved: true,
        approver: (some tx-sender)
      })))))

(define-public (log-emergency-access
    (request-id uint)
    (patient-id (string-ascii 50))
    (data-accessed (string-ascii 100))
    (audit-trail-hash (buff 64)))
  (let ((request (unwrap! (map-get? emergency-requests request-id) ERR-REQUEST-NOT-FOUND))
        (log-id (+ (var-get access-log-counter) u1)))
    (asserts! (get approved request) ERR-NOT-AUTHORIZED)
    (asserts! (< stacks-block-time (get expires-at request)) ERR-ACCESS-EXPIRED)
    (map-set emergency-access-logs log-id
      {
        request-id: request-id,
        responder: tx-sender,
        patient-id: patient-id,
        data-accessed: data-accessed,
        access-timestamp: stacks-block-time,
        audit-trail-hash: audit-trail-hash
      })
    (let ((responder (unwrap! (map-get? emergency-responders tx-sender) ERR-NOT-AUTHORIZED)))
      (map-set emergency-responders tx-sender
        (merge responder { total-accesses: (+ (get total-accesses responder) u1) })))
    (var-set access-log-counter log-id)
    (ok log-id)))

(define-public (set-emergency-contacts
    (primary-contact principal)
    (secondary-contact (optional principal))
    (allow-access bool)
    (restrictions (string-utf8 200)))
  (ok (map-set patient-emergency-contacts tx-sender
    {
      primary-contact: primary-contact,
      secondary-contact: secondary-contact,
      allow-emergency-access: allow-access,
      restrictions: restrictions
    })))

(define-read-only (get-request (request-id uint))
  (ok (map-get? emergency-requests request-id)))

(define-read-only (get-responder (responder principal))
  (ok (map-get? emergency-responders responder)))

(define-read-only (get-access-log (log-id uint))
  (ok (map-get? emergency-access-logs log-id)))

(define-read-only (get-emergency-contacts (patient principal))
  (ok (map-get? patient-emergency-contacts patient)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-request-id (request-id uint))
  (ok (int-to-ascii request-id)))

(define-read-only (parse-request-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
