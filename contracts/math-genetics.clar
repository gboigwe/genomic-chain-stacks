;; math-genetics - Clarity 4
;; Mathematical utility functions for genetic analysis

(define-constant ERR-INVALID-INPUT (err u100))
(define-constant ERR-DIVISION-BY-ZERO (err u101))

(define-read-only (calculate-gc-content (g-count uint) (c-count uint) (total-bases uint))
  (begin
    (asserts! (> total-bases u0) ERR-DIVISION-BY-ZERO)
    (ok (/ (* (+ g-count c-count) u100) total-bases))))

(define-read-only (calculate-allele-frequency (allele-count uint) (total-alleles uint))
  (begin
    (asserts! (> total-alleles u0) ERR-DIVISION-BY-ZERO)
    (ok (/ (* allele-count u1000) total-alleles))))

(define-read-only (hardy-weinberg-p-squared (p uint))
  (ok (/ (* p p) u1000)))

(define-read-only (hardy-weinberg-2pq (p uint) (q uint))
  (ok (/ (* (* u2 p) q) u1000)))

(define-read-only (hardy-weinberg-q-squared (q uint))
  (ok (/ (* q q) u1000)))

(define-read-only (calculate-heterozygosity (p uint))
  (let ((q (- u1000 p)))
    (ok (/ (* (* u2 p) q) u1000000))))

(define-read-only (calculate-snp-density (snp-count uint) (region-length uint))
  (begin
    (asserts! (> region-length u0) ERR-DIVISION-BY-ZERO)
    (ok (/ (* snp-count u1000000) region-length))))

(define-read-only (calculate-mutation-rate (mutations uint) (generations uint) (population uint))
  (begin
    (asserts! (and (> generations u0) (> population u0)) ERR-DIVISION-BY-ZERO)
    (ok (/ mutations (* generations population)))))

(define-read-only (calculate-fst (ht uint) (hs uint))
  (begin
    (asserts! (> ht u0) ERR-DIVISION-BY-ZERO)
    (ok (/ (* (- ht hs) u1000) ht))))

(define-read-only (linkage-disequilibrium (pAB uint) (pA uint) (pB uint))
  (let ((expected (/ (* pA pB) u1000)))
    (ok (if (>= pAB expected)
           (- pAB expected)
           u0))))

(define-read-only (genetic-distance (differences uint) (compared-sites uint))
  (begin
    (asserts! (> compared-sites u0) ERR-DIVISION-BY-ZERO)
    (ok (/ (* differences u1000) compared-sites))))

(define-read-only (effective-population-size (heterozygosity uint) (mutation-rate uint))
  (begin
    (asserts! (> mutation-rate u0) ERR-DIVISION-BY-ZERO)
    (ok (/ heterozygosity (* u4 mutation-rate)))))

(define-read-only (inbreeding-coefficient (observed-heterozygosity uint) (expected-heterozygosity uint))
  (begin
    (asserts! (> expected-heterozygosity u0) ERR-DIVISION-BY-ZERO)
    (ok (/ (* (- expected-heterozygosity observed-heterozygosity) u1000) expected-heterozygosity))))

(define-read-only (calculate-coverage (mapped-reads uint) (read-length uint) (genome-size uint))
  (begin
    (asserts! (> genome-size u0) ERR-DIVISION-BY-ZERO)
    (ok (/ (* mapped-reads read-length) genome-size))))

(define-read-only (phred-quality-score (error-probability uint))
  (ok (* u10 error-probability)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-value (value uint))
  (ok (int-to-ascii value)))

(define-read-only (parse-value (value-str (string-ascii 20)))
  (string-to-uint? value-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
