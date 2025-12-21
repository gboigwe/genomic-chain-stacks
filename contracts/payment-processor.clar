;; payment-processor - Clarity 4
;; Healthcare payment processing and settlement system

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PAYMENT-NOT-FOUND (err u101))
(define-constant ERR-INSUFFICIENT-FUNDS (err u102))
(define-constant ERR-ALREADY-PROCESSED (err u103))

(define-map payment-transactions uint
  {
    payer: principal,
    payee: principal,
    amount: uint,
    payment-type: (string-ascii 50),
    reference-id: (string-ascii 100),
    initiated-at: uint,
    processed-at: (optional uint),
    status: (string-ascii 20)
  }
)

(define-map payment-methods { user: principal, method-id: uint }
  {
    method-type: (string-ascii 20),
    provider: (string-ascii 50),
    account-hash: (buff 64),
    is-verified: bool,
    is-default: bool
  }
)

(define-map escrow-accounts uint
  {
    holder: principal,
    amount: uint,
    release-condition: (string-ascii 100),
    created-at: uint,
    released: bool
  }
)

(define-map transaction-fees uint
  {
    payment-id: uint,
    base-fee: uint,
    processing-fee: uint,
    total-fee: uint,
    fee-recipient: principal
  }
)

(define-data-var payment-counter uint u0)
(define-data-var method-counter uint u0)
(define-data-var escrow-counter uint u0)
(define-data-var base-fee-percentage uint u250) ;; 2.5%

(define-public (initiate-payment
    (payee principal)
    (amount uint)
    (payment-type (string-ascii 50))
    (reference-id (string-ascii 100)))
  (let ((payment-id (+ (var-get payment-counter) u1)))
    (asserts! (> amount u0) ERR-INSUFFICIENT-FUNDS)
    (map-set payment-transactions payment-id
      {
        payer: tx-sender,
        payee: payee,
        amount: amount,
        payment-type: payment-type,
        reference-id: reference-id,
        initiated-at: stacks-block-time,
        processed-at: none,
        status: "pending"
      })
    (var-set payment-counter payment-id)
    (ok payment-id)))

(define-public (process-payment (payment-id uint))
  (let ((payment (unwrap! (map-get? payment-transactions payment-id) ERR-PAYMENT-NOT-FOUND)))
    (asserts! (is-eq (get status payment) "pending") ERR-ALREADY-PROCESSED)
    (let ((fee (calculate-fee (get amount payment))))
      (map-set transaction-fees payment-id
        {
          payment-id: payment-id,
          base-fee: fee,
          processing-fee: u0,
          total-fee: fee,
          fee-recipient: tx-sender
        })
      (ok (map-set payment-transactions payment-id
        (merge payment {
          processed-at: (some stacks-block-time),
          status: "completed"
        }))))))

(define-public (register-payment-method
    (method-type (string-ascii 20))
    (provider (string-ascii 50))
    (account-hash (buff 64))
    (is-default bool))
  (let ((method-id (+ (var-get method-counter) u1)))
    (map-set payment-methods { user: tx-sender, method-id: method-id }
      {
        method-type: method-type,
        provider: provider,
        account-hash: account-hash,
        is-verified: false,
        is-default: is-default
      })
    (var-set method-counter method-id)
    (ok method-id)))

(define-public (create-escrow
    (amount uint)
    (release-condition (string-ascii 100)))
  (let ((escrow-id (+ (var-get escrow-counter) u1)))
    (map-set escrow-accounts escrow-id
      {
        holder: tx-sender,
        amount: amount,
        release-condition: release-condition,
        created-at: stacks-block-time,
        released: false
      })
    (var-set escrow-counter escrow-id)
    (ok escrow-id)))

(define-public (release-escrow (escrow-id uint))
  (let ((escrow (unwrap! (map-get? escrow-accounts escrow-id) ERR-PAYMENT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get holder escrow)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get released escrow)) ERR-ALREADY-PROCESSED)
    (ok (map-set escrow-accounts escrow-id
      (merge escrow { released: true })))))

(define-public (refund-payment (payment-id uint))
  (let ((payment (unwrap! (map-get? payment-transactions payment-id) ERR-PAYMENT-NOT-FOUND)))
    (asserts! (or (is-eq tx-sender (get payer payment))
                  (is-eq tx-sender (get payee payment))) ERR-NOT-AUTHORIZED)
    (ok (map-set payment-transactions payment-id
      (merge payment { status: "refunded" })))))

(define-private (calculate-fee (amount uint))
  (/ (* amount (var-get base-fee-percentage)) u10000))

(define-read-only (get-payment (payment-id uint))
  (ok (map-get? payment-transactions payment-id)))

(define-read-only (get-payment-method (user principal) (method-id uint))
  (ok (map-get? payment-methods { user: user, method-id: method-id })))

(define-read-only (get-escrow (escrow-id uint))
  (ok (map-get? escrow-accounts escrow-id)))

(define-read-only (get-transaction-fee (payment-id uint))
  (ok (map-get? transaction-fees payment-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-payment-id (payment-id uint))
  (ok (int-to-ascii payment-id)))

(define-read-only (parse-payment-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
