;; reimbursement - Clarity 4
;; Healthcare reimbursement claims and processing system

(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-ALREADY-PROCESSED (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))

(define-map reimbursement-claims uint
  {
    claimant: principal,
    procedure-code: (string-ascii 20),
    claim-amount: uint,
    service-date: uint,
    provider: principal,
    status: (string-ascii 20),
    submitted-at: uint,
    processed-at: (optional uint)
  }
)

(define-map claim-reviews uint
  {
    claim-id: uint,
    reviewer: principal,
    decision: (string-ascii 20),
    approved-amount: uint,
    denial-reason: (optional (string-utf8 500)),
    reviewed-at: uint
  }
)

(define-map payment-schedules uint
  {
    claim-id: uint,
    payee: principal,
    amount: uint,
    scheduled-date: uint,
    is-paid: bool,
    paid-at: (optional uint)
  }
)

(define-map claim-appeals uint
  {
    original-claim-id: uint,
    appellant: principal,
    appeal-reason: (string-utf8 500),
    appealed-at: uint,
    appeal-status: (string-ascii 20)
  }
)

(define-data-var claim-counter uint u0)
(define-data-var review-counter uint u0)
(define-data-var payment-counter uint u0)
(define-data-var appeal-counter uint u0)

(define-public (submit-claim
    (procedure-code (string-ascii 20))
    (claim-amount uint)
    (service-date uint)
    (provider principal))
  (let ((claim-id (+ (var-get claim-counter) u1)))
    (map-set reimbursement-claims claim-id
      {
        claimant: tx-sender,
        procedure-code: procedure-code,
        claim-amount: claim-amount,
        service-date: service-date,
        provider: provider,
        status: "pending",
        submitted-at: stacks-block-time,
        processed-at: none
      })
    (var-set claim-counter claim-id)
    (ok claim-id)))

(define-public (review-claim
    (claim-id uint)
    (decision (string-ascii 20))
    (approved-amount uint)
    (denial-reason (optional (string-utf8 500))))
  (let ((claim (unwrap! (map-get? reimbursement-claims claim-id) ERR-NOT-FOUND))
        (review-id (+ (var-get review-counter) u1)))
    (asserts! (is-eq (get status claim) "pending") ERR-ALREADY-PROCESSED)
    (map-set claim-reviews review-id
      {
        claim-id: claim-id,
        reviewer: tx-sender,
        decision: decision,
        approved-amount: approved-amount,
        denial-reason: denial-reason,
        reviewed-at: stacks-block-time
      })
    (map-set reimbursement-claims claim-id
      (merge claim {
        status: decision,
        processed-at: (some stacks-block-time)
      }))
    (var-set review-counter review-id)
    (ok review-id)))

(define-public (schedule-payment
    (claim-id uint)
    (amount uint)
    (scheduled-date uint))
  (let ((claim (unwrap! (map-get? reimbursement-claims claim-id) ERR-NOT-FOUND))
        (payment-id (+ (var-get payment-counter) u1)))
    (asserts! (is-eq (get status claim) "approved") ERR-NOT-AUTHORIZED)
    (map-set payment-schedules payment-id
      {
        claim-id: claim-id,
        payee: (get claimant claim),
        amount: amount,
        scheduled-date: scheduled-date,
        is-paid: false,
        paid-at: none
      })
    (var-set payment-counter payment-id)
    (ok payment-id)))

(define-public (mark-payment-completed (payment-id uint))
  (let ((payment (unwrap! (map-get? payment-schedules payment-id) ERR-NOT-FOUND)))
    (asserts! (not (get is-paid payment)) ERR-ALREADY-PROCESSED)
    (ok (map-set payment-schedules payment-id
      (merge payment {
        is-paid: true,
        paid-at: (some stacks-block-time)
      })))))

(define-public (file-appeal
    (claim-id uint)
    (appeal-reason (string-utf8 500)))
  (let ((claim (unwrap! (map-get? reimbursement-claims claim-id) ERR-NOT-FOUND))
        (appeal-id (+ (var-get appeal-counter) u1)))
    (asserts! (is-eq tx-sender (get claimant claim)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status claim) "denied") ERR-NOT-AUTHORIZED)
    (map-set claim-appeals appeal-id
      {
        original-claim-id: claim-id,
        appellant: tx-sender,
        appeal-reason: appeal-reason,
        appealed-at: stacks-block-time,
        appeal-status: "pending"
      })
    (var-set appeal-counter appeal-id)
    (ok appeal-id)))

(define-read-only (get-claim (claim-id uint))
  (ok (map-get? reimbursement-claims claim-id)))

(define-read-only (get-claim-review (review-id uint))
  (ok (map-get? claim-reviews review-id)))

(define-read-only (get-payment-schedule (payment-id uint))
  (ok (map-get? payment-schedules payment-id)))

(define-read-only (get-appeal (appeal-id uint))
  (ok (map-get? claim-appeals appeal-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-claim-id (claim-id uint))
  (ok (int-to-ascii claim-id)))

(define-read-only (parse-claim-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
