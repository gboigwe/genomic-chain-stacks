;; prediction-market - Clarity 4
;; Prediction markets for healthcare outcomes and genomic research

(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-MARKET-CLOSED (err u102))
(define-constant ERR-ALREADY-RESOLVED (err u103))
(define-constant ERR-INSUFFICIENT-STAKE (err u104))

(define-map prediction-markets uint
  {
    market-question: (string-utf8 500),
    category: (string-ascii 50),
    creator: principal,
    created-at: uint,
    resolution-deadline: uint,
    total-stake: uint,
    is-resolved: bool,
    outcome: (optional (string-ascii 50)),
    resolved-at: (optional uint)
  }
)

(define-map market-outcomes { market-id: uint, outcome: (string-ascii 50) }
  {
    total-stake: uint,
    outcome-probability: uint,
    last-updated: uint
  }
)

(define-map participant-positions { market-id: uint, participant: principal, outcome: (string-ascii 50) }
  {
    stake-amount: uint,
    staked-at: uint,
    is-claimed: bool
  }
)

(define-map market-validators principal
  {
    validator-name: (string-utf8 100),
    total-validations: uint,
    successful-validations: uint,
    reputation-score: uint,
    is-active: bool
  }
)

(define-data-var market-counter uint u0)
(define-data-var min-stake-amount uint u1000)

(define-public (create-market
    (market-question (string-utf8 500))
    (category (string-ascii 50))
    (duration uint))
  (let ((market-id (+ (var-get market-counter) u1)))
    (map-set prediction-markets market-id
      {
        market-question: market-question,
        category: category,
        creator: tx-sender,
        created-at: stacks-block-time,
        resolution-deadline: (+ stacks-block-time duration),
        total-stake: u0,
        is-resolved: false,
        outcome: none,
        resolved-at: none
      })
    (var-set market-counter market-id)
    (ok market-id)))

(define-public (place-stake
    (market-id uint)
    (outcome (string-ascii 50))
    (stake-amount uint))
  (let ((market (unwrap! (map-get? prediction-markets market-id) ERR-NOT-FOUND))
        (current-outcome (default-to
                          { total-stake: u0, outcome-probability: u0, last-updated: u0 }
                          (map-get? market-outcomes { market-id: market-id, outcome: outcome }))))
    (asserts! (> stake-amount (var-get min-stake-amount)) ERR-INSUFFICIENT-STAKE)
    (asserts! (not (get is-resolved market)) ERR-ALREADY-RESOLVED)
    (asserts! (< stacks-block-time (get resolution-deadline market)) ERR-MARKET-CLOSED)
    (map-set participant-positions { market-id: market-id, participant: tx-sender, outcome: outcome }
      {
        stake-amount: stake-amount,
        staked-at: stacks-block-time,
        is-claimed: false
      })
    (map-set market-outcomes { market-id: market-id, outcome: outcome }
      {
        total-stake: (+ (get total-stake current-outcome) stake-amount),
        outcome-probability: u0,
        last-updated: stacks-block-time
      })
    (map-set prediction-markets market-id
      (merge market { total-stake: (+ (get total-stake market) stake-amount) }))
    (ok true)))

(define-public (resolve-market
    (market-id uint)
    (winning-outcome (string-ascii 50)))
  (let ((market (unwrap! (map-get? prediction-markets market-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get creator market)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get is-resolved market)) ERR-ALREADY-RESOLVED)
    (asserts! (>= stacks-block-time (get resolution-deadline market)) ERR-MARKET-CLOSED)
    (ok (map-set prediction-markets market-id
      (merge market {
        is-resolved: true,
        outcome: (some winning-outcome),
        resolved-at: (some stacks-block-time)
      })))))

(define-public (claim-winnings
    (market-id uint)
    (outcome (string-ascii 50)))
  (let ((market (unwrap! (map-get? prediction-markets market-id) ERR-NOT-FOUND))
        (position (unwrap! (map-get? participant-positions { market-id: market-id, participant: tx-sender, outcome: outcome }) ERR-NOT-FOUND)))
    (asserts! (get is-resolved market) ERR-NOT-FOUND)
    (asserts! (is-eq (unwrap! (get outcome market) ERR-NOT-FOUND) outcome) ERR-NOT-AUTHORIZED)
    (asserts! (not (get is-claimed position)) ERR-NOT-AUTHORIZED)
    (ok (map-set participant-positions { market-id: market-id, participant: tx-sender, outcome: outcome }
      (merge position { is-claimed: true })))))

(define-public (register-validator
    (validator-name (string-utf8 100)))
  (ok (map-set market-validators tx-sender
    {
      validator-name: validator-name,
      total-validations: u0,
      successful-validations: u0,
      reputation-score: u50,
      is-active: true
    })))

(define-read-only (get-market (market-id uint))
  (ok (map-get? prediction-markets market-id)))

(define-read-only (get-outcome-stats (market-id uint) (outcome (string-ascii 50)))
  (ok (map-get? market-outcomes { market-id: market-id, outcome: outcome })))

(define-read-only (get-participant-position (market-id uint) (participant principal) (outcome (string-ascii 50)))
  (ok (map-get? participant-positions { market-id: market-id, participant: participant, outcome: outcome })))

(define-read-only (get-validator (validator principal))
  (ok (map-get? market-validators validator)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-market-id (market-id uint))
  (ok (int-to-ascii market-id)))

(define-read-only (parse-market-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
