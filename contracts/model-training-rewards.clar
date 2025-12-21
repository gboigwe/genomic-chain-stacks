;; model-training-rewards - Clarity 4
;; Rewards distribution for ML model training contributions

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-REWARD-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-CLAIMED (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))

(define-map training-contributions uint
  {
    contributor: principal,
    model-id: uint,
    data-samples-provided: uint,
    quality-score: uint,
    contribution-timestamp: uint,
    reward-amount: uint,
    is-claimed: bool
  }
)

(define-map contributor-stats principal
  {
    total-contributions: uint,
    total-rewards-earned: uint,
    total-rewards-claimed: uint,
    average-quality-score: uint,
    reputation-score: uint
  }
)

(define-map reward-pools uint
  {
    model-id: uint,
    total-pool: uint,
    distributed-amount: uint,
    minimum-quality: uint,
    is-active: bool
  }
)

(define-map milestone-rewards uint
  {
    milestone-name: (string-utf8 100),
    threshold: uint,
    reward-multiplier: uint,
    achieved-by: (list 10 principal)
  }
)

(define-data-var contribution-counter uint u0)
(define-data-var pool-counter uint u0)
(define-data-var milestone-counter uint u0)
(define-data-var base-reward-per-sample uint u100)

(define-public (record-contribution
    (model-id uint)
    (data-samples uint)
    (quality-score uint))
  (let ((contribution-id (+ (var-get contribution-counter) u1))
        (reward (calculate-reward data-samples quality-score)))
    (map-set training-contributions contribution-id
      {
        contributor: tx-sender,
        model-id: model-id,
        data-samples-provided: data-samples,
        quality-score: quality-score,
        contribution-timestamp: stacks-block-time,
        reward-amount: reward,
        is-claimed: false
      })
    (update-contributor-stats tx-sender data-samples quality-score reward)
    (var-set contribution-counter contribution-id)
    (ok contribution-id)))

(define-public (claim-reward (contribution-id uint))
  (let ((contribution (unwrap! (map-get? training-contributions contribution-id) ERR-REWARD-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get contributor contribution)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get is-claimed contribution)) ERR-ALREADY-CLAIMED)
    (map-set training-contributions contribution-id
      (merge contribution { is-claimed: true }))
    (try! (update-claimed-stats tx-sender (get reward-amount contribution)))
    (ok (get reward-amount contribution))))

(define-public (create-reward-pool
    (model-id uint)
    (total-pool uint)
    (minimum-quality uint))
  (let ((pool-id (+ (var-get pool-counter) u1)))
    (map-set reward-pools pool-id
      {
        model-id: model-id,
        total-pool: total-pool,
        distributed-amount: u0,
        minimum-quality: minimum-quality,
        is-active: true
      })
    (var-set pool-counter pool-id)
    (ok pool-id)))

(define-public (create-milestone
    (milestone-name (string-utf8 100))
    (threshold uint)
    (multiplier uint))
  (let ((milestone-id (+ (var-get milestone-counter) u1)))
    (map-set milestone-rewards milestone-id
      {
        milestone-name: milestone-name,
        threshold: threshold,
        reward-multiplier: multiplier,
        achieved-by: (list)
      })
    (var-set milestone-counter milestone-id)
    (ok milestone-id)))

(define-private (calculate-reward (samples uint) (quality uint))
  (let ((base (* samples (var-get base-reward-per-sample)))
        (quality-bonus (/ (* base quality) u100)))
    (+ base quality-bonus)))

(define-private (update-contributor-stats (contributor principal) (samples uint) (quality uint) (reward uint))
  (let ((stats (default-to
                 { total-contributions: u0, total-rewards-earned: u0, total-rewards-claimed: u0, average-quality-score: u0, reputation-score: u50 }
                 (map-get? contributor-stats contributor)))
        (new-total (+ (get total-contributions stats) u1))
        (new-avg-quality (/ (+ (* (get average-quality-score stats) (get total-contributions stats)) quality) new-total)))
    (map-set contributor-stats contributor
      {
        total-contributions: new-total,
        total-rewards-earned: (+ (get total-rewards-earned stats) reward),
        total-rewards-claimed: (get total-rewards-claimed stats),
        average-quality-score: new-avg-quality,
        reputation-score: (+ (get reputation-score stats) u1)
      })
    true))

(define-private (update-claimed-stats (contributor principal) (amount uint))
  (let ((stats (unwrap! (map-get? contributor-stats contributor) ERR-NOT-AUTHORIZED)))
    (map-set contributor-stats contributor
      (merge stats { total-rewards-claimed: (+ (get total-rewards-claimed stats) amount) }))
    (ok true)))

(define-read-only (get-contribution (contribution-id uint))
  (ok (map-get? training-contributions contribution-id)))

(define-read-only (get-contributor-stats (contributor principal))
  (ok (map-get? contributor-stats contributor)))

(define-read-only (get-reward-pool (pool-id uint))
  (ok (map-get? reward-pools pool-id)))

(define-read-only (get-milestone (milestone-id uint))
  (ok (map-get? milestone-rewards milestone-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-contribution-id (contribution-id uint))
  (ok (int-to-ascii contribution-id)))

(define-read-only (parse-contribution-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
