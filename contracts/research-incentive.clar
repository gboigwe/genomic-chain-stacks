;; research-incentive.clar - Clarity 4
;; Reward data contributors in research

(define-constant ERR-NOT-AUTHORIZED (err u100))

(define-map participant-rewards
  { participant: principal, project-id: uint }
  {
    contribution-value: uint,
    reward-amount: uint,
    claimed: bool,
    granted-at: uint
  }
)

(define-public (grant-reward
    (participant principal)
    (project-id uint)
    (contribution-value uint)
    (reward-amount uint))
  (begin
    (map-set participant-rewards { participant: participant, project-id: project-id }
      {
        contribution-value: contribution-value,
        reward-amount: reward-amount,
        claimed: false,
        granted-at: stacks-block-time
      })
    (ok true)))

(define-public (claim-reward (project-id uint))
  (let
    ((reward (unwrap! (map-get? participant-rewards { participant: tx-sender, project-id: project-id }) ERR-NOT-AUTHORIZED)))
    (asserts! (not (get claimed reward)) ERR-NOT-AUTHORIZED)
    (map-set participant-rewards { participant: tx-sender, project-id: project-id }
      (merge reward { claimed: true }))
    (ok (get reward-amount reward))))

;; Clarity 4 features
(define-read-only (validate-participant (participant principal))
  (principal-destruct? participant))

(define-read-only (format-project-id (project-id uint))
  (ok (int-to-ascii project-id)))

(define-read-only (get-reward (participant principal) (project-id uint))
  (ok (map-get? participant-rewards { participant: participant, project-id: project-id })))
