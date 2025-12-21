;; privacy-manager - Clarity 4
;; Comprehensive privacy control system for genomic data

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-POLICY-NOT-FOUND (err u101))
(define-constant ERR-INVALID-LEVEL (err u102))
(define-constant ERR-CONSENT-REQUIRED (err u103))
(define-constant ERR-ALREADY-EXISTS (err u104))

(define-constant PRIVACY-LEVEL-PUBLIC u0)
(define-constant PRIVACY-LEVEL-RESTRICTED u1)
(define-constant PRIVACY-LEVEL-CONFIDENTIAL u2)
(define-constant PRIVACY-LEVEL-HIGHLY-CONFIDENTIAL u3)

(define-map privacy-policies uint
  {
    data-owner: principal,
    privacy-level: uint,
    allow-research: bool,
    allow-commercial: bool,
    allow-third-party: bool,
    anonymization-required: bool,
    created-at: uint,
    updated-at: uint
  }
)

(define-map consent-records { policy-id: uint, requester: principal }
  {
    purpose: (string-ascii 100),
    granted: bool,
    granted-at: uint,
    expires-at: uint
  }
)

(define-map data-access-logs uint
  {
    policy-id: uint,
    accessor: principal,
    access-type: (string-ascii 50),
    timestamp: uint,
    approved: bool
  }
)

(define-map anonymization-settings uint
  {
    policy-id: uint,
    remove-identifiers: bool,
    hash-sensitive-fields: bool,
    generalize-locations: bool,
    date-perturbation: bool
  }
)

(define-data-var policy-counter uint u0)
(define-data-var log-counter uint u0)

;; Create privacy policy
(define-public (create-privacy-policy
    (privacy-level uint)
    (allow-research bool)
    (allow-commercial bool)
    (allow-third-party bool)
    (anonymization-required bool))
  (let ((policy-id (+ (var-get policy-counter) u1)))
    (asserts! (<= privacy-level PRIVACY-LEVEL-HIGHLY-CONFIDENTIAL) ERR-INVALID-LEVEL)
    (map-set privacy-policies policy-id
      {
        data-owner: tx-sender,
        privacy-level: privacy-level,
        allow-research: allow-research,
        allow-commercial: allow-commercial,
        allow-third-party: allow-third-party,
        anonymization-required: anonymization-required,
        created-at: stacks-block-time,
        updated-at: stacks-block-time
      })
    (var-set policy-counter policy-id)
    (ok policy-id)))

;; Update privacy level
(define-public (update-privacy-level (policy-id uint) (new-level uint))
  (let ((policy (unwrap! (map-get? privacy-policies policy-id) ERR-POLICY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get data-owner policy)) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-level PRIVACY-LEVEL-HIGHLY-CONFIDENTIAL) ERR-INVALID-LEVEL)
    (ok (map-set privacy-policies policy-id
      (merge policy { privacy-level: new-level, updated-at: stacks-block-time })))))

;; Grant consent for data access
(define-public (grant-consent
    (policy-id uint)
    (requester principal)
    (purpose (string-ascii 100))
    (duration uint))
  (let ((policy (unwrap! (map-get? privacy-policies policy-id) ERR-POLICY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get data-owner policy)) ERR-NOT-AUTHORIZED)
    (ok (map-set consent-records { policy-id: policy-id, requester: requester }
      {
        purpose: purpose,
        granted: true,
        granted-at: stacks-block-time,
        expires-at: (+ stacks-block-time duration)
      }))))

;; Revoke consent
(define-public (revoke-consent (policy-id uint) (requester principal))
  (let ((policy (unwrap! (map-get? privacy-policies policy-id) ERR-POLICY-NOT-FOUND))
        (consent (unwrap! (map-get? consent-records { policy-id: policy-id, requester: requester })
                         ERR-POLICY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get data-owner policy)) ERR-NOT-AUTHORIZED)
    (ok (map-set consent-records { policy-id: policy-id, requester: requester }
      (merge consent { granted: false })))))

;; Request data access
(define-public (request-access (policy-id uint) (access-type (string-ascii 50)))
  (let ((policy (unwrap! (map-get? privacy-policies policy-id) ERR-POLICY-NOT-FOUND))
        (consent (map-get? consent-records { policy-id: policy-id, requester: tx-sender })))
    (let ((has-consent (match consent
                         record (and (get granted record) (< stacks-block-time (get expires-at record)))
                         false)))
      (log-access policy-id tx-sender access-type has-consent)
      (if has-consent
        (ok true)
        ERR-CONSENT-REQUIRED))))

;; Configure anonymization settings
(define-public (set-anonymization-settings
    (policy-id uint)
    (remove-identifiers bool)
    (hash-sensitive-fields bool)
    (generalize-locations bool)
    (date-perturbation bool))
  (let ((policy (unwrap! (map-get? privacy-policies policy-id) ERR-POLICY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get data-owner policy)) ERR-NOT-AUTHORIZED)
    (ok (map-set anonymization-settings policy-id
      {
        policy-id: policy-id,
        remove-identifiers: remove-identifiers,
        hash-sensitive-fields: hash-sensitive-fields,
        generalize-locations: generalize-locations,
        date-perturbation: date-perturbation
      }))))

;; Log access attempt
(define-private (log-access (policy-id uint) (accessor principal) (access-type (string-ascii 50)) (approved bool))
  (let ((log-id (+ (var-get log-counter) u1)))
    (map-set data-access-logs log-id
      {
        policy-id: policy-id,
        accessor: accessor,
        access-type: access-type,
        timestamp: stacks-block-time,
        approved: approved
      })
    (var-set log-counter log-id)
    true))

;; Read-only functions
(define-read-only (get-privacy-policy (policy-id uint))
  (ok (map-get? privacy-policies policy-id)))

(define-read-only (get-consent (policy-id uint) (requester principal))
  (ok (map-get? consent-records { policy-id: policy-id, requester: requester })))

(define-read-only (get-access-log (log-id uint))
  (ok (map-get? data-access-logs log-id)))

(define-read-only (get-anonymization-settings (policy-id uint))
  (ok (map-get? anonymization-settings policy-id)))

(define-read-only (check-access-permission (policy-id uint) (requester principal))
  (let ((consent (map-get? consent-records { policy-id: policy-id, requester: requester })))
    (ok (match consent
          record (and (get granted record) (< stacks-block-time (get expires-at record)))
          false))))

;; Clarity 4: principal-destruct?
(define-read-only (validate-owner (owner principal))
  (principal-destruct? owner))

;; Clarity 4: int-to-ascii
(define-read-only (format-policy-id (policy-id uint))
  (ok (int-to-ascii policy-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-policy-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
