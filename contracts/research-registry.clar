;; research-registry - Clarity 4
;; Research project registration and tracking

(define-constant ERR-PROJECT-NOT-FOUND (err u100))
(define-data-var project-counter uint u0)

(define-map research-projects { project-id: uint }
  { lead-researcher: principal, title: (string-utf8 200), institution: (string-ascii 100), start-date: uint, status: (string-ascii 20), is-approved: bool })

(define-public (register-project (title (string-utf8 200)) (institution (string-ascii 100)) (start-date uint))
  (let ((new-id (+ (var-get project-counter) u1)))
    (map-set research-projects { project-id: new-id }
      { lead-researcher: tx-sender, title: title, institution: institution, start-date: start-date, status: "pending", is-approved: false })
    (var-set project-counter new-id)
    (ok new-id)))

(define-read-only (get-project (project-id uint))
  (ok (map-get? research-projects { project-id: project-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-researcher (researcher principal)) (principal-destruct? researcher))

;; Clarity 4: int-to-ascii
(define-read-only (format-project-id (project-id uint)) (ok (int-to-ascii project-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-project-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
