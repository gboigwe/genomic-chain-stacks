;; research-incentive - Clarity 4
;; Incentive distribution for research participation

(define-constant ERR-REWARD-NOT-FOUND (err u100))
(define-data-var reward-counter uint u0)

(define-map research-rewards { reward-id: uint }
  { participant: principal, project-id: uint, amount: uint, reason: (string-ascii 100), awarded-at: uint, is-claimed: bool })

(define-public (award-reward (participant principal) (project-id uint) (amount uint) (reason (string-ascii 100)))
  (let ((new-id (+ (var-get reward-counter) u1)))
    (map-set research-rewards { reward-id: new-id }
      { participant: participant, project-id: project-id, amount: amount, reason: reason, awarded-at: stacks-block-time, is-claimed: false })
    (var-set reward-counter new-id)
    (ok new-id)))

(define-read-only (get-reward (reward-id uint))
  (ok (map-get? research-rewards { reward-id: reward-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-participant (participant principal)) (principal-destruct? participant))

;; Clarity 4: int-to-ascii
(define-read-only (format-reward-id (reward-id uint)) (ok (int-to-ascii reward-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-reward-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
