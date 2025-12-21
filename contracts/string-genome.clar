;; string-genome.clar - Clarity 4
;; DNA sequence utilities

(define-read-only (concat-sequences (seq1 (string-ascii 100)) (seq2 (string-ascii 100)))
  (ok (concat seq1 seq2)))

;; Clarity 4: int-to-ascii
(define-read-only (format-length (length uint))
  (ok (int-to-ascii length)))

;; Clarity 4: int-to-utf8
(define-read-only (format-position (position uint))
  (ok (int-to-utf8 position)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-position (pos-str (string-ascii 20)))
  (string-to-uint? pos-str))

(define-read-only (is-valid-base (base (string-ascii 1)))
  (or (is-eq base "A")
      (or (is-eq base "C")
          (or (is-eq base "G")
              (is-eq base "T")))))
