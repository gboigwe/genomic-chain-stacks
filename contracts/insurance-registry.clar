;; insurance-registry - Clarity 4
;; Insurance provider registry and verification system

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROVIDER-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-REGISTERED (err u102))

(define-map insurance-providers principal
  {
    provider-name: (string-utf8 200),
    license-number: (string-ascii 100),
    provider-type: (string-ascii 50),
    coverage-types: (list 10 (string-ascii 50)),
    is-verified: bool,
    total-claims-processed: uint,
    approval-rate: uint,
    registered-at: uint
  }
)

(define-map provider-networks uint
  {
    network-name: (string-utf8 100),
    provider: principal,
    participating-facilities: (list 20 principal),
    coverage-areas: (list 10 (string-ascii 50)),
    is-active: bool
  }
)

(define-map coverage-plans uint
  {
    provider: principal,
    plan-name: (string-utf8 100),
    plan-type: (string-ascii 50),
    monthly-premium: uint,
    deductible: uint,
    coverage-limit: uint,
    is-active: bool
  }
)

(define-map provider-ratings { provider: principal, rater: principal }
  {
    rating-score: uint,
    review: (string-utf8 500),
    rated-at: uint
  }
)

(define-data-var network-counter uint u0)
(define-data-var plan-counter uint u0)

(define-public (register-provider
    (provider-name (string-utf8 200))
    (license-number (string-ascii 100))
    (provider-type (string-ascii 50))
    (coverage-types (list 10 (string-ascii 50))))
  (begin
    (asserts! (is-none (map-get? insurance-providers tx-sender)) ERR-ALREADY-REGISTERED)
    (ok (map-set insurance-providers tx-sender
      {
        provider-name: provider-name,
        license-number: license-number,
        provider-type: provider-type,
        coverage-types: coverage-types,
        is-verified: false,
        total-claims-processed: u0,
        approval-rate: u0,
        registered-at: stacks-block-time
      }))))

(define-public (verify-provider (provider principal))
  (let ((provider-data (unwrap! (map-get? insurance-providers provider) ERR-PROVIDER-NOT-FOUND)))
    (ok (map-set insurance-providers provider
      (merge provider-data { is-verified: true })))))

(define-public (create-network
    (network-name (string-utf8 100))
    (participating-facilities (list 20 principal))
    (coverage-areas (list 10 (string-ascii 50))))
  (let ((network-id (+ (var-get network-counter) u1)))
    (map-set provider-networks network-id
      {
        network-name: network-name,
        provider: tx-sender,
        participating-facilities: participating-facilities,
        coverage-areas: coverage-areas,
        is-active: true
      })
    (var-set network-counter network-id)
    (ok network-id)))

(define-public (add-coverage-plan
    (plan-name (string-utf8 100))
    (plan-type (string-ascii 50))
    (monthly-premium uint)
    (deductible uint)
    (coverage-limit uint))
  (let ((plan-id (+ (var-get plan-counter) u1)))
    (map-set coverage-plans plan-id
      {
        provider: tx-sender,
        plan-name: plan-name,
        plan-type: plan-type,
        monthly-premium: monthly-premium,
        deductible: deductible,
        coverage-limit: coverage-limit,
        is-active: true
      })
    (var-set plan-counter plan-id)
    (ok plan-id)))

(define-public (rate-provider
    (provider principal)
    (rating-score uint)
    (review (string-utf8 500)))
  (begin
    (asserts! (<= rating-score u100) (err u104))
    (ok (map-set provider-ratings { provider: provider, rater: tx-sender }
      {
        rating-score: rating-score,
        review: review,
        rated-at: stacks-block-time
      }))))

(define-public (update-claim-stats (provider principal) (approved bool))
  (let ((provider-data (unwrap! (map-get? insurance-providers provider) ERR-PROVIDER-NOT-FOUND))
        (new-total (+ (get total-claims-processed provider-data) u1))
        (new-approval-rate (if approved
                              (/ (* (+ (* (get approval-rate provider-data) (get total-claims-processed provider-data)) u100)) new-total)
                              (/ (* (get approval-rate provider-data) (get total-claims-processed provider-data)) new-total))))
    (ok (map-set insurance-providers provider
      (merge provider-data {
        total-claims-processed: new-total,
        approval-rate: new-approval-rate
      })))))

(define-read-only (get-provider (provider principal))
  (ok (map-get? insurance-providers provider)))

(define-read-only (get-network (network-id uint))
  (ok (map-get? provider-networks network-id)))

(define-read-only (get-coverage-plan (plan-id uint))
  (ok (map-get? coverage-plans plan-id)))

(define-read-only (get-provider-rating (provider principal) (rater principal))
  (ok (map-get? provider-ratings { provider: provider, rater: rater })))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-network-id (network-id uint))
  (ok (int-to-ascii network-id)))

(define-read-only (parse-network-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
