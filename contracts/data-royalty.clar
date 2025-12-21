;; data-royalty - Clarity 4
;; Automated royalty distribution system for genomic data usage

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-ROYALTY-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-DISTRIBUTED (err u103))
(define-constant ERR-INVALID-PERCENTAGE (err u104))
(define-constant ERR-NO-BENEFICIARIES (err u105))

(define-constant MAX-ROYALTY-PERCENTAGE u30) ;; 30% max royalty

(define-map royalty-agreements uint
  {
    data-owner: principal,
    royalty-percentage: uint,
    minimum-payment: uint,
    created-at: uint,
    is-active: bool
  }
)

(define-map royalty-beneficiaries { agreement-id: uint, beneficiary: principal }
  { share-percentage: uint, total-received: uint }
)

(define-map royalty-payments uint
  {
    agreement-id: uint,
    payer: principal,
    amount: uint,
    paid-at: uint,
    distributed: bool
  }
)

(define-map usage-tracking { agreement-id: uint, user: principal }
  { total-usage-count: uint, total-paid: uint, last-payment: uint }
)

(define-data-var agreement-counter uint u0)
(define-data-var payment-counter uint u0)

;; Create royalty agreement
(define-public (create-royalty-agreement
    (royalty-percentage uint)
    (minimum-payment uint))
  (let ((agreement-id (+ (var-get agreement-counter) u1)))
    (asserts! (<= royalty-percentage MAX-ROYALTY-PERCENTAGE) ERR-INVALID-PERCENTAGE)
    (asserts! (> minimum-payment u0) ERR-INVALID-AMOUNT)
    (map-set royalty-agreements agreement-id
      {
        data-owner: tx-sender,
        royalty-percentage: royalty-percentage,
        minimum-payment: minimum-payment,
        created-at: stacks-block-time,
        is-active: true
      })
    (var-set agreement-counter agreement-id)
    (ok agreement-id)))

;; Add beneficiary to agreement
(define-public (add-beneficiary
    (agreement-id uint)
    (beneficiary principal)
    (share-percentage uint))
  (let ((agreement (unwrap! (map-get? royalty-agreements agreement-id) ERR-ROYALTY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get data-owner agreement)) ERR-NOT-AUTHORIZED)
    (asserts! (<= share-percentage u100) ERR-INVALID-PERCENTAGE)
    (ok (map-set royalty-beneficiaries { agreement-id: agreement-id, beneficiary: beneficiary }
      { share-percentage: share-percentage, total-received: u0 }))))

;; Record usage payment
(define-public (record-payment (agreement-id uint) (amount uint))
  (let ((agreement (unwrap! (map-get? royalty-agreements agreement-id) ERR-ROYALTY-NOT-FOUND))
        (payment-id (+ (var-get payment-counter) u1)))
    (asserts! (get is-active agreement) ERR-NOT-AUTHORIZED)
    (asserts! (>= amount (get minimum-payment agreement)) ERR-INVALID-AMOUNT)
    (map-set royalty-payments payment-id
      {
        agreement-id: agreement-id,
        payer: tx-sender,
        amount: amount,
        paid-at: stacks-block-time,
        distributed: false
      })
    (update-usage-tracking agreement-id tx-sender amount)
    (var-set payment-counter payment-id)
    (ok payment-id)))

;; Distribute royalty payment to beneficiaries
(define-public (distribute-payment (payment-id uint) (beneficiary principal))
  (let ((payment (unwrap! (map-get? royalty-payments payment-id) ERR-ROYALTY-NOT-FOUND))
        (agreement-id (get agreement-id payment))
        (beneficiary-info (unwrap! (map-get? royalty-beneficiaries
                                             { agreement-id: agreement-id, beneficiary: beneficiary })
                                   ERR-NO-BENEFICIARIES)))
    (asserts! (not (get distributed payment)) ERR-ALREADY-DISTRIBUTED)
    (let ((share-amount (/ (* (get amount payment) (get share-percentage beneficiary-info)) u100)))
      (map-set royalty-beneficiaries { agreement-id: agreement-id, beneficiary: beneficiary }
        (merge beneficiary-info { total-received: (+ (get total-received beneficiary-info) share-amount) }))
      (ok share-amount))))

;; Mark payment as fully distributed
(define-public (mark-payment-distributed (payment-id uint))
  (let ((payment (unwrap! (map-get? royalty-payments payment-id) ERR-ROYALTY-NOT-FOUND))
        (agreement (unwrap! (map-get? royalty-agreements (get agreement-id payment)) ERR-ROYALTY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get data-owner agreement)) ERR-NOT-AUTHORIZED)
    (ok (map-set royalty-payments payment-id (merge payment { distributed: true })))))

;; Update usage tracking
(define-private (update-usage-tracking (agreement-id uint) (user principal) (amount uint))
  (let ((tracking (default-to
                    { total-usage-count: u0, total-paid: u0, last-payment: u0 }
                    (map-get? usage-tracking { agreement-id: agreement-id, user: user }))))
    (map-set usage-tracking { agreement-id: agreement-id, user: user }
      {
        total-usage-count: (+ (get total-usage-count tracking) u1),
        total-paid: (+ (get total-paid tracking) amount),
        last-payment: stacks-block-time
      })
    true))

;; Deactivate royalty agreement
(define-public (deactivate-agreement (agreement-id uint))
  (let ((agreement (unwrap! (map-get? royalty-agreements agreement-id) ERR-ROYALTY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get data-owner agreement)) ERR-NOT-AUTHORIZED)
    (ok (map-set royalty-agreements agreement-id (merge agreement { is-active: false })))))

;; Read-only functions
(define-read-only (get-agreement (agreement-id uint))
  (ok (map-get? royalty-agreements agreement-id)))

(define-read-only (get-beneficiary-info (agreement-id uint) (beneficiary principal))
  (ok (map-get? royalty-beneficiaries { agreement-id: agreement-id, beneficiary: beneficiary })))

(define-read-only (get-payment (payment-id uint))
  (ok (map-get? royalty-payments payment-id)))

(define-read-only (get-usage-stats (agreement-id uint) (user principal))
  (ok (map-get? usage-tracking { agreement-id: agreement-id, user: user })))

(define-read-only (calculate-royalty-amount (agreement-id uint) (base-amount uint))
  (let ((agreement (unwrap! (map-get? royalty-agreements agreement-id) ERR-ROYALTY-NOT-FOUND)))
    (ok (/ (* base-amount (get royalty-percentage agreement)) u100))))

;; Clarity 4: principal-destruct?
(define-read-only (validate-beneficiary (beneficiary principal))
  (principal-destruct? beneficiary))

;; Clarity 4: int-to-ascii
(define-read-only (format-agreement-id (agreement-id uint))
  (ok (int-to-ascii agreement-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-agreement-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
