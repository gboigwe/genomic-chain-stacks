;; treasury-manager - Clarity 4
;; Treasury and fund management for genomic platform

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-FUNDS (err u101))
(define-constant ERR-ALREADY-EXECUTED (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))

(define-map treasury-accounts uint
  {
    account-name: (string-utf8 100),
    balance: uint,
    account-type: (string-ascii 50),
    created-at: uint,
    manager: principal
  }
)

(define-map fund-allocations uint
  {
    source-account: uint,
    destination: principal,
    amount: uint,
    purpose: (string-utf8 200),
    allocated-at: uint,
    is-released: bool
  }
)

(define-map spending-proposals uint
  {
    proposer: principal,
    amount: uint,
    recipient: principal,
    purpose: (string-utf8 500),
    proposed-at: uint,
    votes-for: uint,
    votes-against: uint,
    is-executed: bool,
    execution-deadline: uint
  }
)

(define-map treasury-transactions uint
  {
    transaction-type: (string-ascii 50),
    account-id: uint,
    amount: uint,
    counterparty: principal,
    executed-at: uint,
    transaction-hash: (buff 64)
  }
)

(define-data-var account-counter uint u0)
(define-data-var allocation-counter uint u0)
(define-data-var proposal-counter uint u0)
(define-data-var transaction-counter uint u0)
(define-data-var treasury-balance uint u0)

(define-public (create-treasury-account
    (account-name (string-utf8 100))
    (account-type (string-ascii 50))
    (initial-balance uint))
  (let ((account-id (+ (var-get account-counter) u1)))
    (map-set treasury-accounts account-id
      {
        account-name: account-name,
        balance: initial-balance,
        account-type: account-type,
        created-at: stacks-block-time,
        manager: tx-sender
      })
    (var-set account-counter account-id)
    (var-set treasury-balance (+ (var-get treasury-balance) initial-balance))
    (ok account-id)))

(define-public (allocate-funds
    (source-account uint)
    (destination principal)
    (amount uint)
    (purpose (string-utf8 200)))
  (let ((account (unwrap! (map-get? treasury-accounts source-account) ERR-NOT-AUTHORIZED))
        (allocation-id (+ (var-get allocation-counter) u1)))
    (asserts! (is-eq tx-sender (get manager account)) ERR-NOT-AUTHORIZED)
    (asserts! (>= (get balance account) amount) ERR-INSUFFICIENT-FUNDS)
    (map-set fund-allocations allocation-id
      {
        source-account: source-account,
        destination: destination,
        amount: amount,
        purpose: purpose,
        allocated-at: stacks-block-time,
        is-released: false
      })
    (map-set treasury-accounts source-account
      (merge account { balance: (- (get balance account) amount) }))
    (var-set allocation-counter allocation-id)
    (ok allocation-id)))

(define-public (create-spending-proposal
    (amount uint)
    (recipient principal)
    (purpose (string-utf8 500))
    (voting-period uint))
  (let ((proposal-id (+ (var-get proposal-counter) u1)))
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (map-set spending-proposals proposal-id
      {
        proposer: tx-sender,
        amount: amount,
        recipient: recipient,
        purpose: purpose,
        proposed-at: stacks-block-time,
        votes-for: u0,
        votes-against: u0,
        is-executed: false,
        execution-deadline: (+ stacks-block-time voting-period)
      })
    (var-set proposal-counter proposal-id)
    (ok proposal-id)))

(define-public (release-allocation (allocation-id uint))
  (let ((allocation (unwrap! (map-get? fund-allocations allocation-id) ERR-NOT-AUTHORIZED)))
    (asserts! (not (get is-released allocation)) ERR-ALREADY-EXECUTED)
    (ok (map-set fund-allocations allocation-id
      (merge allocation { is-released: true })))))

(define-public (record-transaction
    (transaction-type (string-ascii 50))
    (account-id uint)
    (amount uint)
    (counterparty principal)
    (transaction-hash (buff 64)))
  (let ((transaction-id (+ (var-get transaction-counter) u1)))
    (map-set treasury-transactions transaction-id
      {
        transaction-type: transaction-type,
        account-id: account-id,
        amount: amount,
        counterparty: counterparty,
        executed-at: stacks-block-time,
        transaction-hash: transaction-hash
      })
    (var-set transaction-counter transaction-id)
    (ok transaction-id)))

(define-read-only (get-treasury-account (account-id uint))
  (ok (map-get? treasury-accounts account-id)))

(define-read-only (get-allocation (allocation-id uint))
  (ok (map-get? fund-allocations allocation-id)))

(define-read-only (get-spending-proposal (proposal-id uint))
  (ok (map-get? spending-proposals proposal-id)))

(define-read-only (get-transaction (transaction-id uint))
  (ok (map-get? treasury-transactions transaction-id)))

(define-read-only (get-total-treasury-balance)
  (ok (var-get treasury-balance)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-account-id (account-id uint))
  (ok (int-to-ascii account-id)))

(define-read-only (parse-account-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
