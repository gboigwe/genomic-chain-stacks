;; faucet-genomic - Clarity 4
;; Token faucet for genomic token distribution and testing

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-CLAIMED (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-COOLDOWN-ACTIVE (err u103))
(define-constant ERR-FAUCET-DISABLED (err u104))

(define-constant FAUCET-AMOUNT u1000000) ;; 1 token with 6 decimals
(define-constant COOLDOWN-PERIOD u86400) ;; 24 hours

(define-map faucet-claims principal
  {
    claim-count: uint,
    last-claim-time: uint,
    total-claimed: uint,
    first-claim-time: uint
  }
)

(define-map claim-history uint
  {
    claimer: principal,
    amount: uint,
    claimed-at: uint,
    claim-type: (string-ascii 20)
  }
)

(define-map faucet-config { config-key: (string-ascii 20) }
  {
    value: uint,
    updated-at: uint,
    updated-by: principal
  }
)

(define-map whitelisted-addresses principal
  {
    is-whitelisted: bool,
    bonus-multiplier: uint,
    added-at: uint
  }
)

(define-data-var claim-counter uint u0)
(define-data-var faucet-enabled bool true)
(define-data-var faucet-admin principal tx-sender)
(define-data-var total-distributed uint u0)

(define-public (claim-tokens)
  (let ((claimer-data (default-to
                        { claim-count: u0, last-claim-time: u0, total-claimed: u0, first-claim-time: stacks-block-time }
                        (map-get? faucet-claims tx-sender)))
        (claim-id (+ (var-get claim-counter) u1)))
    (asserts! (var-get faucet-enabled) ERR-FAUCET-DISABLED)
    (asserts! (>= (- stacks-block-time (get last-claim-time claimer-data)) COOLDOWN-PERIOD) ERR-COOLDOWN-ACTIVE)
    (map-set faucet-claims tx-sender
      {
        claim-count: (+ (get claim-count claimer-data) u1),
        last-claim-time: stacks-block-time,
        total-claimed: (+ (get total-claimed claimer-data) FAUCET-AMOUNT),
        first-claim-time: (get first-claim-time claimer-data)
      })
    (map-set claim-history claim-id
      {
        claimer: tx-sender,
        amount: FAUCET-AMOUNT,
        claimed-at: stacks-block-time,
        claim-type: "regular"
      })
    (var-set claim-counter claim-id)
    (var-set total-distributed (+ (var-get total-distributed) FAUCET-AMOUNT))
    (ok claim-id)))

(define-public (claim-bonus-tokens)
  (let ((claimer-data (default-to
                        { claim-count: u0, last-claim-time: u0, total-claimed: u0, first-claim-time: stacks-block-time }
                        (map-get? faucet-claims tx-sender)))
        (whitelist-data (unwrap! (map-get? whitelisted-addresses tx-sender) ERR-NOT-AUTHORIZED))
        (bonus-amount (* FAUCET-AMOUNT (get bonus-multiplier whitelist-data)))
        (claim-id (+ (var-get claim-counter) u1)))
    (asserts! (get is-whitelisted whitelist-data) ERR-NOT-AUTHORIZED)
    (asserts! (var-get faucet-enabled) ERR-FAUCET-DISABLED)
    (asserts! (>= (- stacks-block-time (get last-claim-time claimer-data)) COOLDOWN-PERIOD) ERR-COOLDOWN-ACTIVE)
    (map-set faucet-claims tx-sender
      {
        claim-count: (+ (get claim-count claimer-data) u1),
        last-claim-time: stacks-block-time,
        total-claimed: (+ (get total-claimed claimer-data) bonus-amount),
        first-claim-time: (get first-claim-time claimer-data)
      })
    (map-set claim-history claim-id
      {
        claimer: tx-sender,
        amount: bonus-amount,
        claimed-at: stacks-block-time,
        claim-type: "bonus"
      })
    (var-set claim-counter claim-id)
    (var-set total-distributed (+ (var-get total-distributed) bonus-amount))
    (ok claim-id)))

(define-public (add-to-whitelist (address principal) (multiplier uint))
  (begin
    (asserts! (is-eq tx-sender (var-get faucet-admin)) ERR-NOT-AUTHORIZED)
    (ok (map-set whitelisted-addresses address
      {
        is-whitelisted: true,
        bonus-multiplier: multiplier,
        added-at: stacks-block-time
      }))))

(define-public (toggle-faucet (enabled bool))
  (begin
    (asserts! (is-eq tx-sender (var-get faucet-admin)) ERR-NOT-AUTHORIZED)
    (var-set faucet-enabled enabled)
    (ok enabled)))

(define-public (update-config
    (config-key (string-ascii 20))
    (value uint))
  (begin
    (asserts! (is-eq tx-sender (var-get faucet-admin)) ERR-NOT-AUTHORIZED)
    (ok (map-set faucet-config { config-key: config-key }
      {
        value: value,
        updated-at: stacks-block-time,
        updated-by: tx-sender
      }))))

(define-read-only (get-claim-data (address principal))
  (ok (map-get? faucet-claims address)))

(define-read-only (get-claim-history (claim-id uint))
  (ok (map-get? claim-history claim-id)))

(define-read-only (get-whitelist-status (address principal))
  (ok (map-get? whitelisted-addresses address)))

(define-read-only (can-claim (address principal))
  (let ((claimer-data (default-to
                        { claim-count: u0, last-claim-time: u0, total-claimed: u0, first-claim-time: u0 }
                        (map-get? faucet-claims address))))
    (ok (and
          (var-get faucet-enabled)
          (>= (- stacks-block-time (get last-claim-time claimer-data)) COOLDOWN-PERIOD)))))

(define-read-only (get-total-distributed)
  (ok (var-get total-distributed)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-claim-id (claim-id uint))
  (ok (int-to-ascii claim-id)))

(define-read-only (parse-claim-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
