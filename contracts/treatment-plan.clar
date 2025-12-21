;; treatment-plan - Clarity 4
;; Patient treatment plan management

(define-constant ERR-PLAN-NOT-FOUND (err u100))
(define-data-var plan-counter uint u0)

(define-map treatment-plans { plan-id: uint }
  { patient: principal, provider: principal, plan-hash: (buff 64), start-date: uint, end-date: uint, status: (string-ascii 20) })

(define-public (create-plan (patient principal) (plan-hash (buff 64)) (start-date uint) (end-date uint))
  (let ((new-id (+ (var-get plan-counter) u1)))
    (map-set treatment-plans { plan-id: new-id }
      { patient: patient, provider: tx-sender, plan-hash: plan-hash, start-date: start-date, end-date: end-date, status: "active" })
    (var-set plan-counter new-id)
    (ok new-id)))

(define-public (update-status (plan-id uint) (new-status (string-ascii 20)))
  (let ((plan (unwrap! (map-get? treatment-plans { plan-id: plan-id }) ERR-PLAN-NOT-FOUND)))
    (ok (map-set treatment-plans { plan-id: plan-id } (merge plan { status: new-status })))))

(define-read-only (get-plan (plan-id uint))
  (ok (map-get? treatment-plans { plan-id: plan-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-patient (patient principal)) (principal-destruct? patient))

;; Clarity 4: int-to-utf8
(define-read-only (format-plan-id (plan-id uint)) (ok (int-to-utf8 plan-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-plan-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
