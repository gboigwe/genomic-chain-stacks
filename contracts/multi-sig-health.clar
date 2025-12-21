;; multi-sig-health - Clarity 4
;; Multi-signature authorization for sensitive health data operations

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-TRANSACTION-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-SIGNED (err u102))
(define-constant ERR-ALREADY-EXECUTED (err u103))
(define-constant ERR-THRESHOLD-NOT-MET (err u104))

(define-map multi-sig-wallets uint
  {
    wallet-name: (string-utf8 100),
    signers: (list 10 principal),
    required-signatures: uint,
    created-at: uint,
    is-active: bool
  }
)

(define-map pending-transactions uint
  {
    wallet-id: uint,
    transaction-type: (string-ascii 50),
    data-hash: (buff 64),
    proposed-by: principal,
    proposed-at: uint,
    executed: bool,
    execution-timestamp: (optional uint)
  }
)

(define-map transaction-signatures { transaction-id: uint, signer: principal }
  {
    signed-at: uint,
    signature-hash: (buff 64)
  }
)

(define-map signature-counts uint
  { count: uint }
)

(define-data-var wallet-counter uint u0)
(define-data-var transaction-counter uint u0)

(define-public (create-multi-sig-wallet
    (wallet-name (string-utf8 100))
    (signers (list 10 principal))
    (required-signatures uint))
  (let ((wallet-id (+ (var-get wallet-counter) u1)))
    (asserts! (<= required-signatures (len signers)) ERR-NOT-AUTHORIZED)
    (map-set multi-sig-wallets wallet-id
      {
        wallet-name: wallet-name,
        signers: signers,
        required-signatures: required-signatures,
        created-at: stacks-block-time,
        is-active: true
      })
    (var-set wallet-counter wallet-id)
    (ok wallet-id)))

(define-public (propose-transaction
    (wallet-id uint)
    (transaction-type (string-ascii 50))
    (data-hash (buff 64)))
  (let ((wallet (unwrap! (map-get? multi-sig-wallets wallet-id) ERR-TRANSACTION-NOT-FOUND))
        (transaction-id (+ (var-get transaction-counter) u1)))
    (asserts! (is-some (index-of (get signers wallet) tx-sender)) ERR-NOT-AUTHORIZED)
    (map-set pending-transactions transaction-id
      {
        wallet-id: wallet-id,
        transaction-type: transaction-type,
        data-hash: data-hash,
        proposed-by: tx-sender,
        proposed-at: stacks-block-time,
        executed: false,
        execution-timestamp: none
      })
    (map-set signature-counts transaction-id { count: u0 })
    (var-set transaction-counter transaction-id)
    (ok transaction-id)))

(define-public (sign-transaction (transaction-id uint) (signature-hash (buff 64)))
  (let ((transaction (unwrap! (map-get? pending-transactions transaction-id) ERR-TRANSACTION-NOT-FOUND))
        (wallet (unwrap! (map-get? multi-sig-wallets (get wallet-id transaction)) ERR-TRANSACTION-NOT-FOUND)))
    (asserts! (is-some (index-of (get signers wallet) tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? transaction-signatures { transaction-id: transaction-id, signer: tx-sender })) ERR-ALREADY-SIGNED)
    (asserts! (not (get executed transaction)) ERR-ALREADY-EXECUTED)
    (map-set transaction-signatures { transaction-id: transaction-id, signer: tx-sender }
      {
        signed-at: stacks-block-time,
        signature-hash: signature-hash
      })
    (let ((sig-count (unwrap! (map-get? signature-counts transaction-id) ERR-TRANSACTION-NOT-FOUND)))
      (map-set signature-counts transaction-id { count: (+ (get count sig-count) u1) }))
    (ok true)))

(define-public (execute-transaction (transaction-id uint))
  (let ((transaction (unwrap! (map-get? pending-transactions transaction-id) ERR-TRANSACTION-NOT-FOUND))
        (wallet (unwrap! (map-get? multi-sig-wallets (get wallet-id transaction)) ERR-TRANSACTION-NOT-FOUND))
        (sig-count (unwrap! (map-get? signature-counts transaction-id) ERR-TRANSACTION-NOT-FOUND)))
    (asserts! (not (get executed transaction)) ERR-ALREADY-EXECUTED)
    (asserts! (>= (get count sig-count) (get required-signatures wallet)) ERR-THRESHOLD-NOT-MET)
    (ok (map-set pending-transactions transaction-id
      (merge transaction {
        executed: true,
        execution-timestamp: (some stacks-block-time)
      })))))

(define-public (revoke-signature (transaction-id uint))
  (let ((transaction (unwrap! (map-get? pending-transactions transaction-id) ERR-TRANSACTION-NOT-FOUND))
        (signature (unwrap! (map-get? transaction-signatures { transaction-id: transaction-id, signer: tx-sender }) ERR-NOT-AUTHORIZED)))
    (asserts! (not (get executed transaction)) ERR-ALREADY-EXECUTED)
    (map-delete transaction-signatures { transaction-id: transaction-id, signer: tx-sender })
    (let ((sig-count (unwrap! (map-get? signature-counts transaction-id) ERR-TRANSACTION-NOT-FOUND)))
      (map-set signature-counts transaction-id { count: (- (get count sig-count) u1) }))
    (ok true)))

(define-read-only (get-wallet (wallet-id uint))
  (ok (map-get? multi-sig-wallets wallet-id)))

(define-read-only (get-transaction (transaction-id uint))
  (ok (map-get? pending-transactions transaction-id)))

(define-read-only (get-signature (transaction-id uint) (signer principal))
  (ok (map-get? transaction-signatures { transaction-id: transaction-id, signer: signer })))

(define-read-only (get-signature-count (transaction-id uint))
  (ok (map-get? signature-counts transaction-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-transaction-id (transaction-id uint))
  (ok (int-to-ascii transaction-id)))

(define-read-only (parse-transaction-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
