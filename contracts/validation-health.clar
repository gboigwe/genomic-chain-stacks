;; validation-health.clar - Clarity 4
;; Health data validation

(define-read-only (is-valid-age (age uint))
  (and (>= age u0) (<= age u150)))

(define-read-only (is-valid-height (height-cm uint))
  (and (>= height-cm u30) (<= height-cm u300)))

(define-read-only (is-valid-weight (weight-kg uint))
  (and (>= weight-kg u1) (<= weight-kg u500)))

(define-read-only (is-valid-blood-pressure (systolic uint) (diastolic uint))
  (and (>= systolic u60) (<= systolic u300)
       (>= diastolic u40) (<= diastolic u200)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-principal (principal-to-check principal))
  (principal-destruct? principal-to-check))

;; Clarity 4: int-to-ascii
(define-read-only (format-measurement (value uint))
  (ok (int-to-ascii value)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-measurement (value-str (string-ascii 20)))
  (string-to-uint? value-str))
