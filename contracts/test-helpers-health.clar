;; test-helpers-health.clar - Clarity 4
;; Testing utilities for health data

(define-read-only (create-test-patient-id (index uint))
  (ok (+ u1000000 index)))

(define-read-only (create-test-hash (value uint))
  (ok 0x0000000000000000000000000000000000000000000000000000000000000000))

(define-read-only (get-test-timestamp)
  (ok stacks-block-time))

;; Clarity 4: int-to-ascii
(define-read-only (format-test-id (test-id uint))
  (ok (int-to-ascii test-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-test-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: principal-destruct?
(define-read-only (validate-test-principal (test-principal principal))
  (principal-destruct? test-principal))
