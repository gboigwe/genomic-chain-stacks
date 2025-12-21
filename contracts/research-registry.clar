;; research-registry - Clarity 4
;; Research project registration and tracking

(define-constant ERR-PROJECT-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-STATUS (err u102))

(define-map research-projects uint
  {
    lead-researcher: principal,
    co-researchers: (list 10 principal),
    title: (string-utf8 200),
    institution: (string-ascii 100),
    start-date: uint,
    end-date: (optional uint),
    status: (string-ascii 20),
    is-approved: bool,
    funding-amount: uint,
    ethics-approval: bool
  }
)

(define-map project-milestones uint
  {
    project-id: uint,
    milestone-name: (string-utf8 100),
    description: (string-utf8 500),
    target-date: uint,
    completed: bool,
    completed-at: (optional uint)
  }
)

(define-map project-participants uint
  {
    project-id: uint,
    participant: principal,
    role: (string-ascii 50),
    joined-at: uint,
    contribution-score: uint,
    is-active: bool
  }
)

(define-map project-data-access uint
  {
    project-id: uint,
    data-id: uint,
    access-level: (string-ascii 20),
    granted-at: uint,
    expires-at: (optional uint),
    usage-purpose: (string-utf8 200)
  }
)

(define-map ethics-reviews uint
  {
    project-id: uint,
    reviewer: principal,
    approved: bool,
    comments: (string-utf8 500),
    reviewed-at: uint,
    approval-number: (string-ascii 50)
  }
)

(define-data-var project-counter uint u0)
(define-data-var milestone-counter uint u0)
(define-data-var participant-counter uint u0)
(define-data-var access-counter uint u0)
(define-data-var review-counter uint u0)

(define-public (register-project
    (co-researchers (list 10 principal))
    (title (string-utf8 200))
    (institution (string-ascii 100))
    (start-date uint)
    (funding-amount uint))
  (let ((project-id (+ (var-get project-counter) u1)))
    (map-set research-projects project-id
      {
        lead-researcher: tx-sender,
        co-researchers: co-researchers,
        title: title,
        institution: institution,
        start-date: start-date,
        end-date: none,
        status: "pending",
        is-approved: false,
        funding-amount: funding-amount,
        ethics-approval: false
      })
    (var-set project-counter project-id)
    (ok project-id)))

(define-public (approve-project (project-id uint))
  (let ((project (unwrap! (map-get? research-projects project-id) ERR-PROJECT-NOT-FOUND)))
    (ok (map-set research-projects project-id
      (merge project {
        is-approved: true,
        status: "active"
      })))))

(define-public (add-milestone
    (project-id uint)
    (milestone-name (string-utf8 100))
    (description (string-utf8 500))
    (target-date uint))
  (let ((milestone-id (+ (var-get milestone-counter) u1)))
    (asserts! (is-some (map-get? research-projects project-id)) ERR-PROJECT-NOT-FOUND)
    (map-set project-milestones milestone-id
      {
        project-id: project-id,
        milestone-name: milestone-name,
        description: description,
        target-date: target-date,
        completed: false,
        completed-at: none
      })
    (var-set milestone-counter milestone-id)
    (ok milestone-id)))

(define-public (add-participant
    (project-id uint)
    (participant principal)
    (role (string-ascii 50)))
  (let ((participant-id (+ (var-get participant-counter) u1)))
    (asserts! (is-some (map-get? research-projects project-id)) ERR-PROJECT-NOT-FOUND)
    (map-set project-participants participant-id
      {
        project-id: project-id,
        participant: participant,
        role: role,
        joined-at: stacks-block-time,
        contribution-score: u0,
        is-active: true
      })
    (var-set participant-counter participant-id)
    (ok participant-id)))

(define-public (submit-ethics-review
    (project-id uint)
    (approved bool)
    (comments (string-utf8 500))
    (approval-number (string-ascii 50)))
  (let ((review-id (+ (var-get review-counter) u1)))
    (map-set ethics-reviews review-id
      {
        project-id: project-id,
        reviewer: tx-sender,
        approved: approved,
        comments: comments,
        reviewed-at: stacks-block-time,
        approval-number: approval-number
      })
    (var-set review-counter review-id)
    (ok review-id)))

(define-read-only (get-project (project-id uint))
  (ok (map-get? research-projects project-id)))

(define-read-only (get-milestone (milestone-id uint))
  (ok (map-get? project-milestones milestone-id)))

(define-read-only (get-participant (participant-id uint))
  (ok (map-get? project-participants participant-id)))

(define-read-only (get-ethics-review (review-id uint))
  (ok (map-get? ethics-reviews review-id)))

(define-read-only (validate-researcher (researcher principal))
  (principal-destruct? researcher))

(define-read-only (format-project-id (project-id uint))
  (ok (int-to-ascii project-id)))

(define-read-only (parse-project-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
