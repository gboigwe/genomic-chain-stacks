;; patient-rewards - Clarity 4
;; Patient incentive and rewards program for health data sharing

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-REWARD-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-CLAIMED (err u102))
(define-constant ERR-INSUFFICIENT-POINTS (err u103))

(define-map patient-accounts principal
  {
    total-points: uint,
    lifetime-points: uint,
    points-redeemed: uint,
    tier-level: (string-ascii 20),
    joined-at: uint,
    last-activity: uint
  }
)

(define-map reward-activities uint
  {
    patient: principal,
    activity-type: (string-ascii 50),
    points-earned: uint,
    description: (string-utf8 200),
    completed-at: uint,
    verified: bool
  }
)

(define-map reward-catalog uint
  {
    reward-name: (string-utf8 100),
    reward-type: (string-ascii 50),
    points-required: uint,
    stock-available: uint,
    is-active: bool
  }
)

(define-map reward-redemptions uint
  {
    patient: principal,
    reward-id: uint,
    points-spent: uint,
    redeemed-at: uint,
    fulfillment-status: (string-ascii 20)
  }
)

(define-data-var activity-counter uint u0)
(define-data-var catalog-counter uint u0)
(define-data-var redemption-counter uint u0)

(define-public (create-patient-account)
  (ok (map-set patient-accounts tx-sender
    {
      total-points: u0,
      lifetime-points: u0,
      points-redeemed: u0,
      tier-level: "bronze",
      joined-at: stacks-block-time,
      last-activity: stacks-block-time
    })))

(define-public (record-activity
    (activity-type (string-ascii 50))
    (points uint)
    (description (string-utf8 200)))
  (let ((activity-id (+ (var-get activity-counter) u1))
        (account (default-to
                   { total-points: u0, lifetime-points: u0, points-redeemed: u0, tier-level: "bronze", joined-at: stacks-block-time, last-activity: stacks-block-time }
                   (map-get? patient-accounts tx-sender))))
    (map-set reward-activities activity-id
      {
        patient: tx-sender,
        activity-type: activity-type,
        points-earned: points,
        description: description,
        completed-at: stacks-block-time,
        verified: false
      })
    (map-set patient-accounts tx-sender
      (merge account {
        total-points: (+ (get total-points account) points),
        lifetime-points: (+ (get lifetime-points account) points),
        last-activity: stacks-block-time
      }))
    (var-set activity-counter activity-id)
    (ok activity-id)))

(define-public (add-reward-to-catalog
    (reward-name (string-utf8 100))
    (reward-type (string-ascii 50))
    (points-required uint)
    (stock uint))
  (let ((reward-id (+ (var-get catalog-counter) u1)))
    (map-set reward-catalog reward-id
      {
        reward-name: reward-name,
        reward-type: reward-type,
        points-required: points-required,
        stock-available: stock,
        is-active: true
      })
    (var-set catalog-counter reward-id)
    (ok reward-id)))

(define-public (redeem-reward (reward-id uint))
  (let ((reward (unwrap! (map-get? reward-catalog reward-id) ERR-REWARD-NOT-FOUND))
        (account (unwrap! (map-get? patient-accounts tx-sender) ERR-NOT-AUTHORIZED))
        (redemption-id (+ (var-get redemption-counter) u1)))
    (asserts! (get is-active reward) ERR-REWARD-NOT-FOUND)
    (asserts! (> (get stock-available reward) u0) ERR-REWARD-NOT-FOUND)
    (asserts! (>= (get total-points account) (get points-required reward)) ERR-INSUFFICIENT-POINTS)
    (map-set reward-redemptions redemption-id
      {
        patient: tx-sender,
        reward-id: reward-id,
        points-spent: (get points-required reward),
        redeemed-at: stacks-block-time,
        fulfillment-status: "pending"
      })
    (map-set patient-accounts tx-sender
      (merge account {
        total-points: (- (get total-points account) (get points-required reward)),
        points-redeemed: (+ (get points-redeemed account) (get points-required reward))
      }))
    (map-set reward-catalog reward-id
      (merge reward { stock-available: (- (get stock-available reward) u1) }))
    (var-set redemption-counter redemption-id)
    (ok redemption-id)))

(define-public (verify-activity (activity-id uint))
  (let ((activity (unwrap! (map-get? reward-activities activity-id) ERR-REWARD-NOT-FOUND)))
    (ok (map-set reward-activities activity-id
      (merge activity { verified: true })))))

(define-read-only (get-patient-account (patient principal))
  (ok (map-get? patient-accounts patient)))

(define-read-only (get-activity (activity-id uint))
  (ok (map-get? reward-activities activity-id)))

(define-read-only (get-reward (reward-id uint))
  (ok (map-get? reward-catalog reward-id)))

(define-read-only (get-redemption (redemption-id uint))
  (ok (map-get? reward-redemptions redemption-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-activity-id (activity-id uint))
  (ok (int-to-ascii activity-id)))

(define-read-only (parse-activity-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
