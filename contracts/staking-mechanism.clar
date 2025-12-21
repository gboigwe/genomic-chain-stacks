;; staking-mechanism - Clarity 4
;; Token staking mechanism for governance and rewards

(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-ALREADY-STAKED (err u102))
(define-constant ERR-UNSTAKE-LOCKED (err u103))

(define-map staking-positions { staker: principal, pool-id: uint }
  {
    amount-staked: uint,
    staked-at: uint,
    unlock-time: uint,
    rewards-earned: uint,
    is-active: bool
  }
)

(define-map staking-pools uint
  {
    pool-name: (string-utf8 100),
    total-staked: uint,
    reward-rate: uint,
    lock-period: uint,
    min-stake: uint,
    is-active: bool,
    created-at: uint
  }
)

(define-map staker-rewards principal
  {
    total-rewards-earned: uint,
    total-rewards-claimed: uint,
    last-claim: uint,
    reward-multiplier: uint
  }
)

(define-map pool-statistics uint
  {
    pool-id: uint,
    total-stakers: uint,
    total-rewards-distributed: uint,
    average-stake-duration: uint
  }
)

(define-data-var pool-counter uint u0)
(define-data-var total-value-locked uint u0)

(define-public (create-staking-pool
    (pool-name (string-utf8 100))
    (reward-rate uint)
    (lock-period uint)
    (min-stake uint))
  (let ((pool-id (+ (var-get pool-counter) u1)))
    (map-set staking-pools pool-id
      {
        pool-name: pool-name,
        total-staked: u0,
        reward-rate: reward-rate,
        lock-period: lock-period,
        min-stake: min-stake,
        is-active: true,
        created-at: stacks-block-time
      })
    (var-set pool-counter pool-id)
    (ok pool-id)))

(define-public (stake-tokens
    (pool-id uint)
    (amount uint))
  (let ((pool (unwrap! (map-get? staking-pools pool-id) ERR-NOT-FOUND)))
    (asserts! (>= amount (get min-stake pool)) ERR-INSUFFICIENT-BALANCE)
    (asserts! (get is-active pool) ERR-NOT-FOUND)
    (map-set staking-positions { staker: tx-sender, pool-id: pool-id }
      {
        amount-staked: amount,
        staked-at: stacks-block-time,
        unlock-time: (+ stacks-block-time (get lock-period pool)),
        rewards-earned: u0,
        is-active: true
      })
    (map-set staking-pools pool-id
      (merge pool { total-staked: (+ (get total-staked pool) amount) }))
    (var-set total-value-locked (+ (var-get total-value-locked) amount))
    (ok true)))

(define-public (unstake-tokens (pool-id uint))
  (let ((position (unwrap! (map-get? staking-positions { staker: tx-sender, pool-id: pool-id }) ERR-NOT-FOUND))
        (pool (unwrap! (map-get? staking-pools pool-id) ERR-NOT-FOUND)))
    (asserts! (get is-active position) ERR-NOT-FOUND)
    (asserts! (>= stacks-block-time (get unlock-time position)) ERR-UNSTAKE-LOCKED)
    (map-set staking-positions { staker: tx-sender, pool-id: pool-id }
      (merge position { is-active: false }))
    (map-set staking-pools pool-id
      (merge pool { total-staked: (- (get total-staked pool) (get amount-staked position)) }))
    (var-set total-value-locked (- (var-get total-value-locked) (get amount-staked position)))
    (ok (get amount-staked position))))

(define-public (claim-rewards (pool-id uint))
  (let ((position (unwrap! (map-get? staking-positions { staker: tx-sender, pool-id: pool-id }) ERR-NOT-FOUND))
        (rewards (default-to
                  { total-rewards-earned: u0, total-rewards-claimed: u0, last-claim: u0, reward-multiplier: u100 }
                  (map-get? staker-rewards tx-sender))))
    (asserts! (get is-active position) ERR-NOT-FOUND)
    (let ((earned (calculate-rewards position pool-id)))
      (map-set staker-rewards tx-sender
        (merge rewards {
          total-rewards-earned: (+ (get total-rewards-earned rewards) earned),
          total-rewards-claimed: (+ (get total-rewards-claimed rewards) earned),
          last-claim: stacks-block-time
        }))
      (ok earned))))

(define-private (calculate-rewards (position (tuple (amount-staked uint) (staked-at uint) (unlock-time uint) (rewards-earned uint) (is-active bool))) (pool-id uint))
  (let ((pool (unwrap-panic (map-get? staking-pools pool-id)))
        (duration (- stacks-block-time (get staked-at position))))
    (/ (* (* (get amount-staked position) (get reward-rate pool)) duration) u1000000)))

(define-read-only (get-staking-position (staker principal) (pool-id uint))
  (ok (map-get? staking-positions { staker: staker, pool-id: pool-id })))

(define-read-only (get-staking-pool (pool-id uint))
  (ok (map-get? staking-pools pool-id)))

(define-read-only (get-staker-rewards (staker principal))
  (ok (map-get? staker-rewards staker)))

(define-read-only (get-total-value-locked)
  (ok (var-get total-value-locked)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-pool-id (pool-id uint))
  (ok (int-to-ascii pool-id)))

(define-read-only (parse-pool-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
