;; genome-access-control - Clarity 4
;; Fine-grained access control for genomic data

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PERMISSION-NOT-FOUND (err u101))
(define-constant ERR-PERMISSION-EXPIRED (err u102))
(define-constant ERR-INVALID-ROLE (err u103))

(define-map permissions { resource-id: uint, requester: principal }
  {
    granted-by: principal,
    access-level: (string-ascii 20),
    granted-at: uint,
    expires-at: uint,
    scope: (string-ascii 50),
    is-active: bool
  }
)

(define-map access-roles uint
  {
    role-name: (string-ascii 50),
    role-description: (string-utf8 200),
    permissions-list: (list 20 (string-ascii 50)),
    created-at: uint,
    is-active: bool
  }
)

(define-map role-assignments { user: principal, resource-id: uint }
  {
    role-id: uint,
    assigned-by: principal,
    assigned-at: uint,
    expires-at: (optional uint),
    is-active: bool
  }
)

(define-map access-requests uint
  {
    requester: principal,
    resource-id: uint,
    requested-access-level: (string-ascii 20),
    justification: (string-utf8 500),
    requested-at: uint,
    status: (string-ascii 20),
    reviewed-by: (optional principal),
    reviewed-at: (optional uint)
  }
)

(define-map access-logs uint
  {
    user: principal,
    resource-id: uint,
    action: (string-ascii 50),
    access-level: (string-ascii 20),
    timestamp: uint,
    ip-hash: (optional (buff 32)),
    success: bool
  }
)

(define-map delegation-rules uint
  {
    delegator: principal,
    delegate: principal,
    resource-pattern: (string-ascii 100),
    permissions-delegated: (list 10 (string-ascii 50)),
    start-date: uint,
    end-date: uint,
    is-revocable: bool
  }
)

(define-data-var role-counter uint u0)
(define-data-var request-counter uint u0)
(define-data-var log-counter uint u0)
(define-data-var delegation-counter uint u0)

(define-public (grant-permission
    (resource-id uint)
    (grantee principal)
    (access-level (string-ascii 20))
    (expiration uint)
    (scope (string-ascii 50)))
  (begin
    (map-set permissions { resource-id: resource-id, requester: grantee }
      {
        granted-by: tx-sender,
        access-level: access-level,
        granted-at: stacks-block-time,
        expires-at: expiration,
        scope: scope,
        is-active: true
      })
    (ok true)))

(define-public (revoke-permission (resource-id uint) (grantee principal))
  (let ((permission (unwrap! (map-get? permissions { resource-id: resource-id, requester: grantee }) ERR-PERMISSION-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get granted-by permission)) ERR-NOT-AUTHORIZED)
    (ok (map-set permissions { resource-id: resource-id, requester: grantee }
      (merge permission { is-active: false })))))

(define-public (create-access-role
    (role-name (string-ascii 50))
    (role-description (string-utf8 200))
    (permissions-list (list 20 (string-ascii 50))))
  (let ((role-id (+ (var-get role-counter) u1)))
    (map-set access-roles role-id
      {
        role-name: role-name,
        role-description: role-description,
        permissions-list: permissions-list,
        created-at: stacks-block-time,
        is-active: true
      })
    (var-set role-counter role-id)
    (ok role-id)))

(define-public (assign-role
    (user principal)
    (resource-id uint)
    (role-id uint)
    (expires-at (optional uint)))
  (begin
    (asserts! (is-some (map-get? access-roles role-id)) ERR-INVALID-ROLE)
    (map-set role-assignments { user: user, resource-id: resource-id }
      {
        role-id: role-id,
        assigned-by: tx-sender,
        assigned-at: stacks-block-time,
        expires-at: expires-at,
        is-active: true
      })
    (ok true)))

(define-public (request-access
    (resource-id uint)
    (requested-access-level (string-ascii 20))
    (justification (string-utf8 500)))
  (let ((request-id (+ (var-get request-counter) u1)))
    (map-set access-requests request-id
      {
        requester: tx-sender,
        resource-id: resource-id,
        requested-access-level: requested-access-level,
        justification: justification,
        requested-at: stacks-block-time,
        status: "pending",
        reviewed-by: none,
        reviewed-at: none
      })
    (var-set request-counter request-id)
    (ok request-id)))

(define-public (review-access-request
    (request-id uint)
    (approved bool))
  (let ((request (unwrap! (map-get? access-requests request-id) ERR-PERMISSION-NOT-FOUND)))
    (map-set access-requests request-id
      (merge request {
        status: (if approved "approved" "rejected"),
        reviewed-by: (some tx-sender),
        reviewed-at: (some stacks-block-time)
      }))
    (if approved
        (grant-permission
          (get resource-id request)
          (get requester request)
          (get requested-access-level request)
          (+ stacks-block-time u31536000)
          "full")
        (ok true))))

(define-public (log-access
    (resource-id uint)
    (action (string-ascii 50))
    (access-level (string-ascii 20))
    (ip-hash (optional (buff 32)))
    (success bool))
  (let ((log-id (+ (var-get log-counter) u1)))
    (map-set access-logs log-id
      {
        user: tx-sender,
        resource-id: resource-id,
        action: action,
        access-level: access-level,
        timestamp: stacks-block-time,
        ip-hash: ip-hash,
        success: success
      })
    (var-set log-counter log-id)
    (ok log-id)))

(define-public (delegate-access
    (delegate principal)
    (resource-pattern (string-ascii 100))
    (permissions-delegated (list 10 (string-ascii 50)))
    (duration uint)
    (is-revocable bool))
  (let ((delegation-id (+ (var-get delegation-counter) u1)))
    (map-set delegation-rules delegation-id
      {
        delegator: tx-sender,
        delegate: delegate,
        resource-pattern: resource-pattern,
        permissions-delegated: permissions-delegated,
        start-date: stacks-block-time,
        end-date: (+ stacks-block-time duration),
        is-revocable: is-revocable
      })
    (var-set delegation-counter delegation-id)
    (ok delegation-id)))

(define-read-only (check-permission (resource-id uint) (requester principal))
  (ok (map-get? permissions { resource-id: resource-id, requester: requester })))

(define-read-only (get-role (role-id uint))
  (ok (map-get? access-roles role-id)))

(define-read-only (get-role-assignment (user principal) (resource-id uint))
  (ok (map-get? role-assignments { user: user, resource-id: resource-id })))

(define-read-only (get-access-request (request-id uint))
  (ok (map-get? access-requests request-id)))

(define-read-only (get-access-log (log-id uint))
  (ok (map-get? access-logs log-id)))

(define-read-only (get-delegation (delegation-id uint))
  (ok (map-get? delegation-rules delegation-id)))

(define-read-only (is-permission-valid (resource-id uint) (requester principal))
  (let ((permission (map-get? permissions { resource-id: resource-id, requester: requester })))
    (ok (if (is-some permission)
            (let ((perm (unwrap-panic permission)))
              (and
                (get is-active perm)
                (> (get expires-at perm) stacks-block-time)))
            false))))

(define-read-only (validate-requester (requester principal))
  (principal-destruct? requester))

(define-read-only (format-resource-id (resource-id uint))
  (ok (int-to-ascii resource-id)))

(define-read-only (parse-resource-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
