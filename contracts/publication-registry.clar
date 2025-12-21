;; publication-registry - Clarity 4
;; Research publication tracking and attribution

(define-constant ERR-PUBLICATION-NOT-FOUND (err u100))
(define-data-var publication-counter uint u0)

(define-map publications { publication-id: uint }
  { author: principal, title: (string-utf8 200), doi: (string-ascii 100), data-refs: (list 10 uint), published-at: uint })

(define-public (register-publication (title (string-utf8 200)) (doi (string-ascii 100)) (data-refs (list 10 uint)))
  (let ((new-id (+ (var-get publication-counter) u1)))
    (map-set publications { publication-id: new-id }
      { author: tx-sender, title: title, doi: doi, data-refs: data-refs, published-at: stacks-block-time })
    (var-set publication-counter new-id)
    (ok new-id)))

(define-read-only (get-publication (publication-id uint))
  (ok (map-get? publications { publication-id: publication-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-author (author principal)) (principal-destruct? author))

;; Clarity 4: int-to-utf8
(define-read-only (format-publication-id (publication-id uint)) (ok (int-to-utf8 publication-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-publication-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
