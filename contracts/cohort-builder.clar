;; cohort-builder.clar - Clarity 4
;; Build research cohorts from patient data

(define-constant ERR-NOT-AUTHORIZED (err u100))

(define-data-var cohort-counter uint u0)

(define-map cohorts
  { cohort-id: uint }
  {
    researcher: principal,
    name: (string-utf8 100),
    criteria: (string-utf8 500),
    size: uint,
    created-at: uint,
    is-active: bool
  }
)

(define-public (create-cohort
    (name (string-utf8 100))
    (criteria (string-utf8 500))
    (target-size uint))
  (let
    ((new-id (+ (var-get cohort-counter) u1)))
    (map-set cohorts { cohort-id: new-id }
      {
        researcher: tx-sender,
        name: name,
        criteria: criteria,
        size: target-size,
        created-at: stacks-block-time,
        is-active: true
      })
    (var-set cohort-counter new-id)
    (ok new-id)))

;; Clarity 4 features
(define-read-only (validate-researcher (researcher principal))
  (principal-destruct? researcher))

(define-read-only (format-cohort-id (cohort-id uint))
  (ok (int-to-ascii cohort-id)))

(define-read-only (get-cohort (cohort-id uint))
  (ok (map-get? cohorts { cohort-id: cohort-id })))
