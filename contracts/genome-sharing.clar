;; genome-sharing - Clarity 4
;; Secure sharing of genomic data between parties

(define-constant ERR-SHARE-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-SHARE-EXPIRED (err u102))
(define-constant ERR-ALREADY-REVOKED (err u103))

(define-map shares uint
  {
    owner: principal,
    recipient: principal,
    data-ref: uint,
    shared-at: uint,
    expires-at: uint,
    is-active: bool,
    access-level: (string-ascii 20),
    usage-purpose: (string-utf8 200),
    consent-given: bool
  }
)

(define-map share-access-logs uint
  {
    share-id: uint,
    accessor: principal,
    accessed-at: uint,
    action: (string-ascii 50),
    data-retrieved: (buff 32)
  }
)

(define-map sharing-agreements uint
  {
    share-id: uint,
    terms: (string-utf8 500),
    data-usage-restrictions: (list 10 (string-ascii 50)),
    agreed-at: uint,
    agreement-hash: (buff 64)
  }
)

(define-map recipient-groups uint
  {
    group-name: (string-utf8 100),
    owner: principal,
    members: (list 20 principal),
    default-access-level: (string-ascii 20),
    created-at: uint,
    is-active: bool
  }
)

(define-map sharing-notifications uint
  {
    share-id: uint,
    recipient: principal,
    notification-type: (string-ascii 50),
    message: (string-utf8 300),
    sent-at: uint,
    read: bool
  }
)

(define-data-var share-counter uint u0)
(define-data-var access-log-counter uint u0)
(define-data-var agreement-counter uint u0)
(define-data-var group-counter uint u0)
(define-data-var notification-counter uint u0)

(define-public (create-share
    (recipient principal)
    (data-ref uint)
    (expiration uint)
    (access-level (string-ascii 20))
    (usage-purpose (string-utf8 200))
    (consent-given bool))
  (let ((share-id (+ (var-get share-counter) u1)))
    (map-set shares share-id
      {
        owner: tx-sender,
        recipient: recipient,
        data-ref: data-ref,
        shared-at: stacks-block-time,
        expires-at: expiration,
        is-active: true,
        access-level: access-level,
        usage-purpose: usage-purpose,
        consent-given: consent-given
      })
    (var-set share-counter share-id)
    (ok share-id)))

(define-public (revoke-share (share-id uint))
  (let ((share (unwrap! (map-get? shares share-id) ERR-SHARE-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner share)) ERR-NOT-AUTHORIZED)
    (asserts! (get is-active share) ERR-ALREADY-REVOKED)
    (ok (map-set shares share-id
      (merge share { is-active: false })))))

(define-public (log-share-access
    (share-id uint)
    (action (string-ascii 50))
    (data-retrieved (buff 32)))
  (let ((log-id (+ (var-get access-log-counter) u1))
        (share (unwrap! (map-get? shares share-id) ERR-SHARE-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get recipient share)) ERR-NOT-AUTHORIZED)
    (asserts! (get is-active share) ERR-ALREADY-REVOKED)
    (map-set share-access-logs log-id
      {
        share-id: share-id,
        accessor: tx-sender,
        accessed-at: stacks-block-time,
        action: action,
        data-retrieved: data-retrieved
      })
    (var-set access-log-counter log-id)
    (ok log-id)))

(define-public (create-sharing-agreement
    (share-id uint)
    (terms (string-utf8 500))
    (data-usage-restrictions (list 10 (string-ascii 50)))
    (agreement-hash (buff 64)))
  (let ((agreement-id (+ (var-get agreement-counter) u1)))
    (asserts! (is-some (map-get? shares share-id)) ERR-SHARE-NOT-FOUND)
    (map-set sharing-agreements agreement-id
      {
        share-id: share-id,
        terms: terms,
        data-usage-restrictions: data-usage-restrictions,
        agreed-at: stacks-block-time,
        agreement-hash: agreement-hash
      })
    (var-set agreement-counter agreement-id)
    (ok agreement-id)))

(define-public (create-recipient-group
    (group-name (string-utf8 100))
    (members (list 20 principal))
    (default-access-level (string-ascii 20)))
  (let ((group-id (+ (var-get group-counter) u1)))
    (map-set recipient-groups group-id
      {
        group-name: group-name,
        owner: tx-sender,
        members: members,
        default-access-level: default-access-level,
        created-at: stacks-block-time,
        is-active: true
      })
    (var-set group-counter group-id)
    (ok group-id)))

(define-read-only (get-share (share-id uint))
  (ok (map-get? shares share-id)))

(define-read-only (get-access-log (log-id uint))
  (ok (map-get? share-access-logs log-id)))

(define-read-only (get-agreement (agreement-id uint))
  (ok (map-get? sharing-agreements agreement-id)))

(define-read-only (get-recipient-group (group-id uint))
  (ok (map-get? recipient-groups group-id)))

(define-read-only (is-share-active (share-id uint))
  (let ((share (map-get? shares share-id)))
    (ok (if (is-some share)
            (let ((s (unwrap-panic share)))
              (and
                (get is-active s)
                (> (get expires-at s) stacks-block-time)))
            false))))

(define-read-only (validate-recipient (recipient principal))
  (principal-destruct? recipient))

(define-read-only (format-share-id (share-id uint))
  (ok (int-to-ascii share-id)))

(define-read-only (parse-share-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
