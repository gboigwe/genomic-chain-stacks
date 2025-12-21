;; treatment-plan.clar - Clarity 4
;; Treatment plans and care management

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PLAN-NOT-FOUND (err u101))

(define-data-var plan-counter uint u0)

(define-map treatment-plans
  { plan-id: uint }
  {
    patient: principal,
    provider: principal,
    diagnosis-ref: uint,
    plan-description: (string-utf8 500),
    start-date: uint,
    end-date: uint,
    status: (string-ascii 20),
    created-at: uint,
    updated-at: uint
  }
)

(define-public (create-plan
    (patient principal)
    (diagnosis-ref uint)
    (plan-description (string-utf8 500))
    (duration uint))
  (let
    ((new-id (+ (var-get plan-counter) u1))
     (end-date (+ stacks-block-time duration)))
    (map-set treatment-plans { plan-id: new-id }
      {
        patient: patient,
        provider: tx-sender,
        diagnosis-ref: diagnosis-ref,
        plan-description: plan-description,
        start-date: stacks-block-time,
        end-date: end-date,
        status: "active",
        created-at: stacks-block-time,
        updated-at: stacks-block-time
      })
    (var-set plan-counter new-id)
    (ok new-id)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-patient (patient principal))
  (principal-destruct? patient))

;; Clarity 4: int-to-utf8
(define-read-only (format-plan-id (plan-id uint))
  (ok (int-to-utf8 plan-id)))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-height)
  (ok burn-block-height))

(define-read-only (get-treatment-plan (plan-id uint))
  (ok (map-get? treatment-plans { plan-id: plan-id })))
