;; encoding-genome.clar - Clarity 4
;; Genome encoding (ACGT)

(define-constant ERR-INVALID-BASE (err u300))

(define-read-only (encode-base (base (string-ascii 1)))
  (if (is-eq base "A") (ok u0)
  (if (is-eq base "C") (ok u1)
  (if (is-eq base "G") (ok u2)
  (if (is-eq base "T") (ok u3)
  ERR-INVALID-BASE)))))

(define-read-only (decode-base (code uint))
  (if (is-eq code u0) (ok "A")
  (if (is-eq code u1) (ok "C")
  (if (is-eq code u2) (ok "G")
  (if (is-eq code u3) (ok "T")
  ERR-INVALID-BASE)))))

;; Clarity 4: int-to-ascii
(define-read-only (format-code (code uint))
  (ok (int-to-ascii code)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-code (code-str (string-ascii 20)))
  (string-to-uint? code-str))

;; Clarity 4: buff-to-uint-le
(define-read-only (buffer-to-code (buff-data (buff 16)))
  (ok (buff-to-uint-le buff-data)))
