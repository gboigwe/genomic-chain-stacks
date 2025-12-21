;; publication-registry - Clarity 4
;; Research publication tracking and attribution

(define-constant ERR-PUBLICATION-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-ALREADY-PUBLISHED (err u102))

(define-map publications uint
  {
    author: principal,
    co-authors: (list 10 principal),
    title: (string-utf8 200),
    doi: (string-ascii 100),
    data-refs: (list 10 uint),
    published-at: uint,
    journal: (string-utf8 100),
    citation-count: uint,
    is-peer-reviewed: bool
  }
)

(define-map citations uint
  {
    citing-publication: uint,
    cited-publication: uint,
    citation-context: (string-utf8 300),
    cited-at: uint
  }
)

(define-map data-attribution uint
  {
    publication-id: uint,
    data-id: uint,
    usage-type: (string-ascii 50),
    contribution-level: (string-ascii 20)
  }
)

(define-map peer-reviews uint
  {
    publication-id: uint,
    reviewer: principal,
    rating: uint,
    comments: (string-utf8 500),
    reviewed-at: uint,
    recommendation: (string-ascii 50)
  }
)

(define-map impact-metrics uint
  {
    publication-id: uint,
    views: uint,
    downloads: uint,
    citations: uint,
    h-index: uint,
    updated-at: uint
  }
)

(define-data-var publication-counter uint u0)
(define-data-var citation-counter uint u0)
(define-data-var attribution-counter uint u0)
(define-data-var review-counter uint u0)
(define-data-var metrics-counter uint u0)

(define-public (register-publication
    (co-authors (list 10 principal))
    (title (string-utf8 200))
    (doi (string-ascii 100))
    (data-refs (list 10 uint))
    (journal (string-utf8 100))
    (is-peer-reviewed bool))
  (let ((pub-id (+ (var-get publication-counter) u1)))
    (map-set publications pub-id
      {
        author: tx-sender,
        co-authors: co-authors,
        title: title,
        doi: doi,
        data-refs: data-refs,
        published-at: stacks-block-time,
        journal: journal,
        citation-count: u0,
        is-peer-reviewed: is-peer-reviewed
      })
    (var-set publication-counter pub-id)
    (ok pub-id)))

(define-public (add-citation
    (citing-publication uint)
    (cited-publication uint)
    (citation-context (string-utf8 300)))
  (let ((citation-id (+ (var-get citation-counter) u1))
        (pub (unwrap! (map-get? publications cited-publication) ERR-PUBLICATION-NOT-FOUND)))
    (map-set citations citation-id
      {
        citing-publication: citing-publication,
        cited-publication: cited-publication,
        citation-context: citation-context,
        cited-at: stacks-block-time
      })
    (map-set publications cited-publication
      (merge pub { citation-count: (+ (get citation-count pub) u1) }))
    (var-set citation-counter citation-id)
    (ok citation-id)))

(define-public (attribute-data
    (publication-id uint)
    (data-id uint)
    (usage-type (string-ascii 50))
    (contribution-level (string-ascii 20)))
  (let ((attribution-id (+ (var-get attribution-counter) u1)))
    (asserts! (is-some (map-get? publications publication-id)) ERR-PUBLICATION-NOT-FOUND)
    (map-set data-attribution attribution-id
      {
        publication-id: publication-id,
        data-id: data-id,
        usage-type: usage-type,
        contribution-level: contribution-level
      })
    (var-set attribution-counter attribution-id)
    (ok attribution-id)))

(define-public (submit-peer-review
    (publication-id uint)
    (rating uint)
    (comments (string-utf8 500))
    (recommendation (string-ascii 50)))
  (let ((review-id (+ (var-get review-counter) u1)))
    (asserts! (is-some (map-get? publications publication-id)) ERR-PUBLICATION-NOT-FOUND)
    (map-set peer-reviews review-id
      {
        publication-id: publication-id,
        reviewer: tx-sender,
        rating: rating,
        comments: comments,
        reviewed-at: stacks-block-time,
        recommendation: recommendation
      })
    (var-set review-counter review-id)
    (ok review-id)))

(define-public (update-impact-metrics
    (publication-id uint)
    (views uint)
    (downloads uint)
    (citation-count uint)
    (h-index uint))
  (let ((metrics-id (+ (var-get metrics-counter) u1)))
    (asserts! (is-some (map-get? publications publication-id)) ERR-PUBLICATION-NOT-FOUND)
    (map-set impact-metrics metrics-id
      {
        publication-id: publication-id,
        views: views,
        downloads: downloads,
        citations: citation-count,
        h-index: h-index,
        updated-at: stacks-block-time
      })
    (var-set metrics-counter metrics-id)
    (ok metrics-id)))

(define-read-only (get-publication (publication-id uint))
  (ok (map-get? publications publication-id)))

(define-read-only (get-citation (citation-id uint))
  (ok (map-get? citations citation-id)))

(define-read-only (get-attribution (attribution-id uint))
  (ok (map-get? data-attribution attribution-id)))

(define-read-only (get-peer-review (review-id uint))
  (ok (map-get? peer-reviews review-id)))

(define-read-only (get-impact-metrics (metrics-id uint))
  (ok (map-get? impact-metrics metrics-id)))

(define-read-only (validate-author (author principal))
  (principal-destruct? author))

(define-read-only (format-publication-id (publication-id uint))
  (ok (int-to-ascii publication-id)))

(define-read-only (parse-publication-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
