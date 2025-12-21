;; research-incentive - Clarity 4
;; Incentive distribution for research participation

(define-constant ERR-REWARD-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-ALREADY-CLAIMED (err u102))

(define-map research-rewards uint
  {
    participant: principal,
    project-id: uint,
    amount: uint,
    reason: (string-ascii 100),
    awarded-at: uint,
    is-claimed: bool,
    awarded-by: principal,
    contribution-type: (string-ascii 50)
  }
)

(define-map reward-tiers uint
  {
    tier-name: (string-utf8 50),
    min-contribution: uint,
    reward-multiplier: uint,
    benefits: (list 5 (string-utf8 100)),
    is-active: bool
  }
)

(define-map participant-stats uint
  {
    participant: principal,
    total-earned: uint,
    total-claimed: uint,
    projects-joined: uint,
    current-tier: uint,
    last-activity: uint
  }
)

(define-map milestone-bonuses uint
  {
    project-id: uint,
    milestone-name: (string-utf8 100),
    bonus-amount: uint,
    criteria: (string-utf8 300),
    achieved-by: (optional principal),
    achieved-at: (optional uint)
  }
)

(define-data-var reward-counter uint u0)
(define-data-var tier-counter uint u0)
(define-data-var stats-counter uint u0)
(define-data-var bonus-counter uint u0)

(define-public (award-reward
    (participant principal)
    (project-id uint)
    (amount uint)
    (reason (string-ascii 100))
    (contribution-type (string-ascii 50)))
  (let ((reward-id (+ (var-get reward-counter) u1)))
    (map-set research-rewards reward-id
      {
        participant: participant,
        project-id: project-id,
        amount: amount,
        reason: reason,
        awarded-at: stacks-block-time,
        is-claimed: false,
        awarded-by: tx-sender,
        contribution-type: contribution-type
      })
    (var-set reward-counter reward-id)
    (ok reward-id)))

(define-public (claim-reward (reward-id uint))
  (let ((reward (unwrap! (map-get? research-rewards reward-id) ERR-REWARD-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get participant reward)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get is-claimed reward)) ERR-ALREADY-CLAIMED)
    (ok (map-set research-rewards reward-id
      (merge reward { is-claimed: true })))))

(define-public (create-reward-tier
    (tier-name (string-utf8 50))
    (min-contribution uint)
    (reward-multiplier uint)
    (benefits (list 5 (string-utf8 100))))
  (let ((tier-id (+ (var-get tier-counter) u1)))
    (map-set reward-tiers tier-id
      {
        tier-name: tier-name,
        min-contribution: min-contribution,
        reward-multiplier: reward-multiplier,
        benefits: benefits,
        is-active: true
      })
    (var-set tier-counter tier-id)
    (ok tier-id)))

(define-public (update-participant-stats
    (participant principal)
    (total-earned uint)
    (total-claimed uint)
    (projects-joined uint)
    (current-tier uint))
  (let ((stats-id (+ (var-get stats-counter) u1)))
    (map-set participant-stats stats-id
      {
        participant: participant,
        total-earned: total-earned,
        total-claimed: total-claimed,
        projects-joined: projects-joined,
        current-tier: current-tier,
        last-activity: stacks-block-time
      })
    (var-set stats-counter stats-id)
    (ok stats-id)))

(define-public (create-milestone-bonus
    (project-id uint)
    (milestone-name (string-utf8 100))
    (bonus-amount uint)
    (criteria (string-utf8 300)))
  (let ((bonus-id (+ (var-get bonus-counter) u1)))
    (map-set milestone-bonuses bonus-id
      {
        project-id: project-id,
        milestone-name: milestone-name,
        bonus-amount: bonus-amount,
        criteria: criteria,
        achieved-by: none,
        achieved-at: none
      })
    (var-set bonus-counter bonus-id)
    (ok bonus-id)))

(define-read-only (get-reward (reward-id uint))
  (ok (map-get? research-rewards reward-id)))

(define-read-only (get-tier (tier-id uint))
  (ok (map-get? reward-tiers tier-id)))

(define-read-only (get-participant-stats (stats-id uint))
  (ok (map-get? participant-stats stats-id)))

(define-read-only (get-milestone-bonus (bonus-id uint))
  (ok (map-get? milestone-bonuses bonus-id)))

(define-read-only (validate-participant (participant principal))
  (principal-destruct? participant))

(define-read-only (format-reward-id (reward-id uint))
  (ok (int-to-ascii reward-id)))

(define-read-only (parse-reward-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
