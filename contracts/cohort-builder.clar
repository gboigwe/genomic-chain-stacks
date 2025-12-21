;; cohort-builder - Clarity 4
;; Build patient cohorts for research studies

(define-constant ERR-COHORT-NOT-FOUND (err u100))
(define-data-var cohort-counter uint u0)

(define-map cohorts { cohort-id: uint }
  { creator: principal, name: (string-utf8 100), criteria-hash: (buff 64), member-count: uint, created-at: uint, is-active: bool })

(define-public (create-cohort (name (string-utf8 100)) (criteria-hash (buff 64)))
  (let ((new-id (+ (var-get cohort-counter) u1)))
    (map-set cohorts { cohort-id: new-id }
      { creator: tx-sender, name: name, criteria-hash: criteria-hash, member-count: u0, created-at: stacks-block-time, is-active: true })
    (var-set cohort-counter new-id)
    (ok new-id)))

(define-read-only (get-cohort (cohort-id uint))
  (ok (map-get? cohorts { cohort-id: cohort-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-creator (creator principal)) (principal-destruct? creator))

;; Clarity 4: int-to-ascii
(define-read-only (format-cohort-id (cohort-id uint)) (ok (int-to-ascii cohort-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-cohort-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
