;; fee-collector - Clarity 4
;; Fee collection and distribution system for platform operations

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-FUNDS (err u101))
(define-constant ERR-INVALID-RECIPIENT (err u102))
(define-constant ERR-INVALID-PERCENTAGE (err u103))

(define-map fee-types (string-ascii 50)
  {
    fee-name: (string-utf8 100),
    fee-percentage: uint,
    total-collected: uint,
    is-active: bool,
    created-at: uint
  }
)

(define-map fee-distributions uint
  {
    fee-type: (string-ascii 50),
    amount: uint,
    distributed-to: principal,
    distributed-at: uint,
    distribution-reason: (string-utf8 200)
  }
)

(define-map revenue-recipients principal
  {
    allocation-percentage: uint,
    total-received: uint,
    last-payment: uint,
    is-active: bool
  }
)

(define-map fee-collection-history uint
  {
    fee-type: (string-ascii 50),
    collected-from: principal,
    amount: uint,
    transaction-id: (buff 64),
    collected-at: uint
  }
)

(define-data-var distribution-counter uint u0)
(define-data-var collection-counter uint u0)
(define-data-var treasury-balance uint u0)
(define-data-var platform-admin principal tx-sender)

(define-public (register-fee-type
    (fee-id (string-ascii 50))
    (fee-name (string-utf8 100))
    (fee-percentage uint))
  (begin
    (asserts! (is-eq tx-sender (var-get platform-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (<= fee-percentage u10000) ERR-INVALID-PERCENTAGE) ;; Max 100% (100.00)
    (ok (map-set fee-types fee-id
      {
        fee-name: fee-name,
        fee-percentage: fee-percentage,
        total-collected: u0,
        is-active: true,
        created-at: stacks-block-time
      }))))

(define-public (collect-fee
    (fee-type (string-ascii 50))
    (amount uint)
    (transaction-id (buff 64)))
  (let ((fee-info (unwrap! (map-get? fee-types fee-type) ERR-INVALID-RECIPIENT))
        (collection-id (+ (var-get collection-counter) u1)))
    (asserts! (get is-active fee-info) ERR-NOT-AUTHORIZED)
    (map-set fee-collection-history collection-id
      {
        fee-type: fee-type,
        collected-from: tx-sender,
        amount: amount,
        transaction-id: transaction-id,
        collected-at: stacks-block-time
      })
    (map-set fee-types fee-type
      (merge fee-info { total-collected: (+ (get total-collected fee-info) amount) }))
    (var-set treasury-balance (+ (var-get treasury-balance) amount))
    (var-set collection-counter collection-id)
    (ok collection-id)))

(define-public (distribute-fees
    (fee-type (string-ascii 50))
    (recipient principal)
    (amount uint)
    (reason (string-utf8 200)))
  (let ((distribution-id (+ (var-get distribution-counter) u1))
        (recipient-info (default-to
                          { allocation-percentage: u0, total-received: u0, last-payment: u0, is-active: false }
                          (map-get? revenue-recipients recipient))))
    (asserts! (is-eq tx-sender (var-get platform-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (<= amount (var-get treasury-balance)) ERR-INSUFFICIENT-FUNDS)
    (map-set fee-distributions distribution-id
      {
        fee-type: fee-type,
        amount: amount,
        distributed-to: recipient,
        distributed-at: stacks-block-time,
        distribution-reason: reason
      })
    (map-set revenue-recipients recipient
      {
        allocation-percentage: (get allocation-percentage recipient-info),
        total-received: (+ (get total-received recipient-info) amount),
        last-payment: stacks-block-time,
        is-active: true
      })
    (var-set treasury-balance (- (var-get treasury-balance) amount))
    (var-set distribution-counter distribution-id)
    (ok distribution-id)))

(define-public (set-recipient-allocation
    (recipient principal)
    (percentage uint))
  (begin
    (asserts! (is-eq tx-sender (var-get platform-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (<= percentage u10000) ERR-INVALID-PERCENTAGE)
    (let ((existing (default-to
                      { allocation-percentage: u0, total-received: u0, last-payment: u0, is-active: false }
                      (map-get? revenue-recipients recipient))))
      (ok (map-set revenue-recipients recipient
        (merge existing { allocation-percentage: percentage, is-active: true }))))))

(define-public (toggle-fee-type (fee-id (string-ascii 50)) (active bool))
  (let ((fee-info (unwrap! (map-get? fee-types fee-id) ERR-INVALID-RECIPIENT)))
    (asserts! (is-eq tx-sender (var-get platform-admin)) ERR-NOT-AUTHORIZED)
    (ok (map-set fee-types fee-id
      (merge fee-info { is-active: active })))))

(define-read-only (get-fee-type (fee-id (string-ascii 50)))
  (ok (map-get? fee-types fee-id)))

(define-read-only (get-distribution (distribution-id uint))
  (ok (map-get? fee-distributions distribution-id)))

(define-read-only (get-recipient-info (recipient principal))
  (ok (map-get? revenue-recipients recipient)))

(define-read-only (get-collection-history (collection-id uint))
  (ok (map-get? fee-collection-history collection-id)))

(define-read-only (get-treasury-balance)
  (ok (var-get treasury-balance)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-distribution-id (distribution-id uint))
  (ok (int-to-ascii distribution-id)))

(define-read-only (parse-distribution-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
