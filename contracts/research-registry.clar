;; research-registry.clar - Clarity 4
;; Research project registry

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROJECT-NOT-FOUND (err u101))

(define-data-var project-counter uint u0)

(define-map research-projects
  { project-id: uint }
  {
    principal-investigator: principal,
    title: (string-utf8 200),
    description: (string-utf8 500),
    start-date: uint,
    end-date: uint,
    status: (string-ascii 20),
    funding-amount: uint,
    participants-needed: uint,
    participants-enrolled: uint,
    created-at: uint
  }
)

(define-public (register-project
    (title (string-utf8 200))
    (description (string-utf8 500))
    (duration uint)
    (funding-amount uint)
    (participants-needed uint))
  (let
    ((new-id (+ (var-get project-counter) u1))
     (end-date (+ stacks-block-time duration)))
    (map-set research-projects { project-id: new-id }
      {
        principal-investigator: tx-sender,
        title: title,
        description: description,
        start-date: stacks-block-time,
        end-date: end-date,
        status: "active",
        funding-amount: funding-amount,
        participants-needed: participants-needed,
        participants-enrolled: u0,
        created-at: stacks-block-time
      })
    (var-set project-counter new-id)
    (ok new-id)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-investigator (investigator principal))
  (principal-destruct? investigator))

;; Clarity 4: int-to-ascii
(define-read-only (format-project-id (project-id uint))
  (ok (int-to-ascii project-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-project-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-height)
  (ok burn-block-height))

(define-read-only (get-project (project-id uint))
  (ok (map-get? research-projects { project-id: project-id })))
