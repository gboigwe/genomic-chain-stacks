;; math-genetics.clar - Clarity 4
;; Genetic calculations and utilities

(define-constant ERR-DIVISION-BY-ZERO (err u200))
(define-constant ERR-OVERFLOW (err u201))

(define-read-only (safe-multiply (a uint) (b uint))
  (ok (* a b)))

(define-read-only (safe-divide (a uint) (b uint))
  (begin
    (asserts! (> b u0) ERR-DIVISION-BY-ZERO)
    (ok (/ a b))))

(define-read-only (safe-add (a uint) (b uint))
  (ok (+ a b)))

(define-read-only (safe-subtract (a uint) (b uint))
  (ok (if (>= a b) (- a b) u0)))

(define-read-only (percentage (value uint) (percent uint))
  (ok (/ (* value percent) u100)))

(define-read-only (min (a uint) (b uint))
  (ok (if (< a b) a b)))

(define-read-only (max (a uint) (b uint))
  (ok (if (> a b) a b)))

;; Clarity 4: int-to-ascii
(define-read-only (format-number (num uint))
  (ok (int-to-ascii num)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-number (num-str (string-ascii 20)))
  (string-to-uint? num-str))

;; Clarity 4: buff-to-uint-le
(define-read-only (buffer-to-uint (buff-data (buff 16)))
  (ok (buff-to-uint-le buff-data)))
