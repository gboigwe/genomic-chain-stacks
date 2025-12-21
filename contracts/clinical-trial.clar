;; clinical-trial.clar - Clarity 4
;; Clinical trial management

(define-constant ERR-NOT-AUTHORIZED (err u100))

(define-data-var trial-counter uint u0)

(define-map clinical-trials
  { trial-id: uint }
  {
    sponsor: principal,
    title: (string-utf8 200),
    phase: uint,
    start-date: uint,
    end-date: uint,
    enrollment-target: uint,
    status: (string-ascii 20)
  }
)

(define-public (register-trial
    (title (string-utf8 200))
    (phase uint)
    (duration uint)
    (enrollment-target uint))
  (let
    ((new-id (+ (var-get trial-counter) u1)))
    (map-set clinical-trials { trial-id: new-id }
      {
        sponsor: tx-sender,
        title: title,
        phase: phase,
        start-date: stacks-block-time,
        end-date: (+ stacks-block-time duration),
        enrollment-target: enrollment-target,
        status: "recruiting"
      })
    (var-set trial-counter new-id)
    (ok new-id)))

;; Clarity 4 features
(define-read-only (validate-sponsor (sponsor principal))
  (principal-destruct? sponsor))

(define-read-only (format-trial-id (trial-id uint))
  (ok (int-to-utf8 trial-id)))

(define-read-only (get-trial (trial-id uint))
  (ok (map-get? clinical-trials { trial-id: trial-id })))
