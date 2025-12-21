;; lab-results - Clarity 4
;; Laboratory test results management

(define-constant ERR-RESULT-NOT-FOUND (err u100))
(define-data-var result-counter uint u0)

(define-map lab-results { result-id: uint }
  { patient: principal, lab: principal, test-type: (string-ascii 100), result-hash: (buff 64), performed-at: uint, is-verified: bool })

(define-public (submit-result (patient principal) (test-type (string-ascii 100)) (result-hash (buff 64)))
  (let ((new-id (+ (var-get result-counter) u1)))
    (map-set lab-results { result-id: new-id }
      { patient: patient, lab: tx-sender, test-type: test-type, result-hash: result-hash, performed-at: stacks-block-time, is-verified: false })
    (var-set result-counter new-id)
    (ok new-id)))

(define-read-only (get-result (result-id uint))
  (ok (map-get? lab-results { result-id: result-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-lab (lab principal)) (principal-destruct? lab))

;; Clarity 4: int-to-utf8
(define-read-only (format-result-id (result-id uint)) (ok (int-to-utf8 result-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-result-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
