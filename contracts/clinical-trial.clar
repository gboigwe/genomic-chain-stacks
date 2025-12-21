;; clinical-trial - Clarity 4
;; Clinical trial management and tracking

(define-constant ERR-TRIAL-NOT-FOUND (err u100))
(define-data-var trial-counter uint u0)

(define-map clinical-trials { trial-id: uint }
  { sponsor: principal, title: (string-utf8 200), nct-id: (string-ascii 50), start-date: uint, phase: (string-ascii 20), status: (string-ascii 20) })

(define-public (register-trial (title (string-utf8 200)) (nct-id (string-ascii 50)) (start-date uint) (phase (string-ascii 20)))
  (let ((new-id (+ (var-get trial-counter) u1)))
    (map-set clinical-trials { trial-id: new-id }
      { sponsor: tx-sender, title: title, nct-id: nct-id, start-date: start-date, phase: phase, status: "active" })
    (var-set trial-counter new-id)
    (ok new-id)))

(define-read-only (get-trial (trial-id uint))
  (ok (map-get? clinical-trials { trial-id: trial-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-sponsor (sponsor principal)) (principal-destruct? sponsor))

;; Clarity 4: int-to-utf8
(define-read-only (format-trial-id (trial-id uint)) (ok (int-to-utf8 trial-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-trial-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
