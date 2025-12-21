;; cross-chain-health - Clarity 4
;; Cross-chain health data bridging and interoperability

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-TRANSFER-NOT-FOUND (err u101))
(define-constant ERR-INVALID-CHAIN (err u102))
(define-constant ERR-TRANSFER-PENDING (err u103))
(define-constant ERR-ALREADY-PROCESSED (err u104))

(define-map cross-chain-transfers uint
  {
    source-chain: (string-ascii 50),
    destination-chain: (string-ascii 50),
    data-hash: (buff 64),
    sender: principal,
    recipient: (string-utf8 100),
    initiated-at: uint,
    status: (string-ascii 20),
    bridge-fee: uint
  }
)

(define-map bridge-validators principal
  {
    validator-name: (string-utf8 100),
    supported-chains: (list 10 (string-ascii 50)),
    total-validations: uint,
    is-active: bool,
    reputation-score: uint
  }
)

(define-map transfer-validations { transfer-id: uint, validator: principal }
  {
    is-approved: bool,
    validation-proof: (buff 64),
    validated-at: uint,
    notes: (string-utf8 200)
  }
)

(define-map chain-configurations (string-ascii 50)
  {
    chain-name: (string-utf8 100),
    bridge-address: (string-utf8 100),
    min-confirmations: uint,
    is-enabled: bool,
    total-transfers: uint
  }
)

(define-map transfer-receipts uint
  {
    transfer-id: uint,
    completion-proof: (buff 64),
    completed-at: uint,
    final-status: (string-ascii 20)
  }
)

(define-data-var transfer-counter uint u0)
(define-data-var receipt-counter uint u0)
(define-data-var min-validator-threshold uint u3)

(define-public (initiate-transfer
    (source-chain (string-ascii 50))
    (destination-chain (string-ascii 50))
    (data-hash (buff 64))
    (recipient (string-utf8 100))
    (bridge-fee uint))
  (let ((transfer-id (+ (var-get transfer-counter) u1))
        (source-config (unwrap! (map-get? chain-configurations source-chain) ERR-INVALID-CHAIN))
        (dest-config (unwrap! (map-get? chain-configurations destination-chain) ERR-INVALID-CHAIN)))
    (asserts! (get is-enabled source-config) ERR-INVALID-CHAIN)
    (asserts! (get is-enabled dest-config) ERR-INVALID-CHAIN)
    (map-set cross-chain-transfers transfer-id
      {
        source-chain: source-chain,
        destination-chain: destination-chain,
        data-hash: data-hash,
        sender: tx-sender,
        recipient: recipient,
        initiated-at: stacks-block-time,
        status: "pending",
        bridge-fee: bridge-fee
      })
    (map-set chain-configurations source-chain
      (merge source-config { total-transfers: (+ (get total-transfers source-config) u1) }))
    (var-set transfer-counter transfer-id)
    (ok transfer-id)))

(define-public (register-validator
    (validator-name (string-utf8 100))
    (supported-chains (list 10 (string-ascii 50))))
  (ok (map-set bridge-validators tx-sender
    {
      validator-name: validator-name,
      supported-chains: supported-chains,
      total-validations: u0,
      is-active: true,
      reputation-score: u50
    })))

(define-public (validate-transfer
    (transfer-id uint)
    (is-approved bool)
    (validation-proof (buff 64))
    (notes (string-utf8 200)))
  (let ((transfer (unwrap! (map-get? cross-chain-transfers transfer-id) ERR-TRANSFER-NOT-FOUND))
        (validator (unwrap! (map-get? bridge-validators tx-sender) ERR-NOT-AUTHORIZED)))
    (asserts! (get is-active validator) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status transfer) "pending") ERR-ALREADY-PROCESSED)
    (map-set transfer-validations { transfer-id: transfer-id, validator: tx-sender }
      {
        is-approved: is-approved,
        validation-proof: validation-proof,
        validated-at: stacks-block-time,
        notes: notes
      })
    (map-set bridge-validators tx-sender
      (merge validator { total-validations: (+ (get total-validations validator) u1) }))
    (ok true)))

(define-public (complete-transfer
    (transfer-id uint)
    (completion-proof (buff 64)))
  (let ((transfer (unwrap! (map-get? cross-chain-transfers transfer-id) ERR-TRANSFER-NOT-FOUND))
        (receipt-id (+ (var-get receipt-counter) u1)))
    (asserts! (is-eq (get sender transfer) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status transfer) "pending") ERR-ALREADY-PROCESSED)
    (map-set cross-chain-transfers transfer-id
      (merge transfer { status: "completed" }))
    (map-set transfer-receipts receipt-id
      {
        transfer-id: transfer-id,
        completion-proof: completion-proof,
        completed-at: stacks-block-time,
        final-status: "completed"
      })
    (var-set receipt-counter receipt-id)
    (ok receipt-id)))

(define-public (configure-chain
    (chain-id-param (string-ascii 50))
    (chain-name (string-utf8 100))
    (bridge-address (string-utf8 100))
    (min-confirmations uint))
  (begin
    (map-set chain-configurations chain-id-param
      {
        chain-name: chain-name,
        bridge-address: bridge-address,
        min-confirmations: min-confirmations,
        is-enabled: true,
        total-transfers: u0
      })
    (ok true)))

(define-public (cancel-transfer (transfer-id uint))
  (let ((transfer (unwrap! (map-get? cross-chain-transfers transfer-id) ERR-TRANSFER-NOT-FOUND)))
    (asserts! (is-eq (get sender transfer) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status transfer) "pending") ERR-ALREADY-PROCESSED)
    (ok (map-set cross-chain-transfers transfer-id
      (merge transfer { status: "cancelled" })))))

(define-read-only (get-transfer (transfer-id uint))
  (ok (map-get? cross-chain-transfers transfer-id)))

(define-read-only (get-validator (validator principal))
  (ok (map-get? bridge-validators validator)))

(define-read-only (get-validation (transfer-id uint) (validator principal))
  (ok (map-get? transfer-validations { transfer-id: transfer-id, validator: validator })))

(define-read-only (get-chain-config (chain-id-param (string-ascii 50)))
  (ok (map-get? chain-configurations chain-id-param)))

(define-read-only (get-transfer-receipt (receipt-id uint))
  (ok (map-get? transfer-receipts receipt-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-transfer-id (transfer-id uint))
  (ok (int-to-ascii transfer-id)))

(define-read-only (parse-transfer-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
