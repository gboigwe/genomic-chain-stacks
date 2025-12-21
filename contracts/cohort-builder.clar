;; cohort-builder - Clarity 4
;; Build patient cohorts for research studies

(define-constant ERR-COHORT-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-MEMBER-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-CRITERIA (err u103))

(define-map cohorts uint
  {
    creator: principal,
    name: (string-utf8 100),
    description: (string-utf8 500),
    criteria-hash: (buff 64),
    member-count: uint,
    created-at: uint,
    updated-at: uint,
    is-active: bool,
    study-type: (string-ascii 50)
  }
)

(define-map cohort-members { cohort-id: uint, member: principal }
  {
    enrolled-at: uint,
    enrolled-by: principal,
    status: (string-ascii 20),
    consent-given: bool,
    data-contribution-level: (string-ascii 50)
  }
)

(define-map inclusion-criteria uint
  {
    cohort-id: uint,
    criterion-name: (string-utf8 100),
    criterion-type: (string-ascii 50),
    operator: (string-ascii 20),
    value: (string-utf8 200),
    is-required: bool
  }
)

(define-map exclusion-criteria uint
  {
    cohort-id: uint,
    criterion-name: (string-utf8 100),
    criterion-type: (string-ascii 50),
    reason: (string-utf8 300)
  }
)

(define-map cohort-statistics uint
  {
    cohort-id: uint,
    total-members: uint,
    active-members: uint,
    average-age: uint,
    data-completeness: uint,
    last-updated: uint
  }
)

(define-map cohort-tags uint
  {
    cohort-id: uint,
    tag-name: (string-ascii 50),
    tag-category: (string-ascii 50),
    added-at: uint
  }
)

(define-data-var cohort-counter uint u0)
(define-data-var inclusion-counter uint u0)
(define-data-var exclusion-counter uint u0)
(define-data-var statistics-counter uint u0)
(define-data-var tag-counter uint u0)

(define-public (create-cohort
    (name (string-utf8 100))
    (description (string-utf8 500))
    (criteria-hash (buff 64))
    (study-type (string-ascii 50)))
  (let ((cohort-id (+ (var-get cohort-counter) u1)))
    (map-set cohorts cohort-id
      {
        creator: tx-sender,
        name: name,
        description: description,
        criteria-hash: criteria-hash,
        member-count: u0,
        created-at: stacks-block-time,
        updated-at: stacks-block-time,
        is-active: true,
        study-type: study-type
      })
    (var-set cohort-counter cohort-id)
    (ok cohort-id)))

(define-public (add-member
    (cohort-id uint)
    (member principal)
    (consent-given bool)
    (data-contribution-level (string-ascii 50)))
  (let ((cohort (unwrap! (map-get? cohorts cohort-id) ERR-COHORT-NOT-FOUND)))
    (asserts! (get is-active cohort) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? cohort-members { cohort-id: cohort-id, member: member })) ERR-MEMBER-ALREADY-EXISTS)
    (map-set cohort-members { cohort-id: cohort-id, member: member }
      {
        enrolled-at: stacks-block-time,
        enrolled-by: tx-sender,
        status: "active",
        consent-given: consent-given,
        data-contribution-level: data-contribution-level
      })
    (map-set cohorts cohort-id
      (merge cohort {
        member-count: (+ (get member-count cohort) u1),
        updated-at: stacks-block-time
      }))
    (ok true)))

(define-public (add-inclusion-criterion
    (cohort-id uint)
    (criterion-name (string-utf8 100))
    (criterion-type (string-ascii 50))
    (operator (string-ascii 20))
    (value (string-utf8 200))
    (is-required bool))
  (let ((criterion-id (+ (var-get inclusion-counter) u1)))
    (asserts! (is-some (map-get? cohorts cohort-id)) ERR-COHORT-NOT-FOUND)
    (map-set inclusion-criteria criterion-id
      {
        cohort-id: cohort-id,
        criterion-name: criterion-name,
        criterion-type: criterion-type,
        operator: operator,
        value: value,
        is-required: is-required
      })
    (var-set inclusion-counter criterion-id)
    (ok criterion-id)))

(define-public (add-exclusion-criterion
    (cohort-id uint)
    (criterion-name (string-utf8 100))
    (criterion-type (string-ascii 50))
    (reason (string-utf8 300)))
  (let ((criterion-id (+ (var-get exclusion-counter) u1)))
    (asserts! (is-some (map-get? cohorts cohort-id)) ERR-COHORT-NOT-FOUND)
    (map-set exclusion-criteria criterion-id
      {
        cohort-id: cohort-id,
        criterion-name: criterion-name,
        criterion-type: criterion-type,
        reason: reason
      })
    (var-set exclusion-counter criterion-id)
    (ok criterion-id)))

(define-public (update-cohort-statistics
    (cohort-id uint)
    (total-members uint)
    (active-members uint)
    (average-age uint)
    (data-completeness uint))
  (let ((stats-id (+ (var-get statistics-counter) u1)))
    (asserts! (is-some (map-get? cohorts cohort-id)) ERR-COHORT-NOT-FOUND)
    (map-set cohort-statistics stats-id
      {
        cohort-id: cohort-id,
        total-members: total-members,
        active-members: active-members,
        average-age: average-age,
        data-completeness: data-completeness,
        last-updated: stacks-block-time
      })
    (var-set statistics-counter stats-id)
    (ok stats-id)))

(define-public (tag-cohort
    (cohort-id uint)
    (tag-name (string-ascii 50))
    (tag-category (string-ascii 50)))
  (let ((tag-id (+ (var-get tag-counter) u1)))
    (asserts! (is-some (map-get? cohorts cohort-id)) ERR-COHORT-NOT-FOUND)
    (map-set cohort-tags tag-id
      {
        cohort-id: cohort-id,
        tag-name: tag-name,
        tag-category: tag-category,
        added-at: stacks-block-time
      })
    (var-set tag-counter tag-id)
    (ok tag-id)))

(define-public (update-member-status
    (cohort-id uint)
    (member principal)
    (new-status (string-ascii 20)))
  (let ((member-data (unwrap! (map-get? cohort-members { cohort-id: cohort-id, member: member }) ERR-COHORT-NOT-FOUND)))
    (ok (map-set cohort-members { cohort-id: cohort-id, member: member }
      (merge member-data { status: new-status })))))

(define-public (deactivate-cohort (cohort-id uint))
  (let ((cohort (unwrap! (map-get? cohorts cohort-id) ERR-COHORT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get creator cohort)) ERR-NOT-AUTHORIZED)
    (ok (map-set cohorts cohort-id
      (merge cohort { is-active: false, updated-at: stacks-block-time })))))

(define-read-only (get-cohort (cohort-id uint))
  (ok (map-get? cohorts cohort-id)))

(define-read-only (get-member (cohort-id uint) (member principal))
  (ok (map-get? cohort-members { cohort-id: cohort-id, member: member })))

(define-read-only (get-inclusion-criterion (criterion-id uint))
  (ok (map-get? inclusion-criteria criterion-id)))

(define-read-only (get-exclusion-criterion (criterion-id uint))
  (ok (map-get? exclusion-criteria criterion-id)))

(define-read-only (get-statistics (stats-id uint))
  (ok (map-get? cohort-statistics stats-id)))

(define-read-only (get-tag (tag-id uint))
  (ok (map-get? cohort-tags tag-id)))

(define-read-only (validate-creator (creator principal))
  (principal-destruct? creator))

(define-read-only (format-cohort-id (cohort-id uint))
  (ok (int-to-ascii cohort-id)))

(define-read-only (parse-cohort-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
