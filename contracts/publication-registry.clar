;; publication-registry.clar - Clarity 4
;; Research publications registry

(define-constant ERR-NOT-AUTHORIZED (err u100))

(define-data-var publication-counter uint u0)

(define-map publications
  { publication-id: uint }
  {
    authors: (list 10 principal),
    title: (string-utf8 200),
    doi: (string-ascii 100),
    published-at: uint,
    data-refs: (list 5 uint)
  }
)

(define-public (register-publication
    (authors (list 10 principal))
    (title (string-utf8 200))
    (doi (string-ascii 100))
    (data-refs (list 5 uint)))
  (let
    ((new-id (+ (var-get publication-counter) u1)))
    (map-set publications { publication-id: new-id }
      {
        authors: authors,
        title: title,
        doi: doi,
        published-at: stacks-block-time,
        data-refs: data-refs
      })
    (var-set publication-counter new-id)
    (ok new-id)))

;; Clarity 4 features
(define-read-only (format-publication-id (publication-id uint))
  (ok (int-to-utf8 publication-id)))

(define-read-only (get-publication (publication-id uint))
  (ok (map-get? publications { publication-id: publication-id })))
