;; lab-results.clar - Clarity 4
;; Laboratory test results storage

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-RESULT-NOT-FOUND (err u101))

(define-data-var result-counter uint u0)

(define-map lab-results
  { result-id: uint }
  {
    patient: principal,
    lab: principal,
    test-type: (string-ascii 100),
    result-data: (buff 256),
    test-date: uint,
    reported-at: uint,
    reference-range: (string-ascii 100),
    is-abnormal: bool,
    is-verified: bool
  }
)

(define-public (submit-result
    (patient principal)
    (test-type (string-ascii 100))
    (result-data (buff 256))
    (test-date uint)
    (reference-range (string-ascii 100))
    (is-abnormal bool))
  (let
    ((new-id (+ (var-get result-counter) u1)))
    (map-set lab-results { result-id: new-id }
      {
        patient: patient,
        lab: tx-sender,
        test-type: test-type,
        result-data: result-data,
        test-date: test-date,
        reported-at: stacks-block-time,
        reference-range: reference-range,
        is-abnormal: is-abnormal,
        is-verified: false
      })
    (var-set result-counter new-id)
    (ok new-id)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-patient (patient principal))
  (principal-destruct? patient))

;; Clarity 4: int-to-utf8
(define-read-only (format-result-id (result-id uint))
  (ok (int-to-utf8 result-id)))

;; Clarity 4: buff-to-uint-le
(define-read-only (result-to-number (result-buff (buff 16)))
  (ok (buff-to-uint-le result-buff)))

(define-read-only (get-lab-result (result-id uint))
  (ok (map-get? lab-results { result-id: result-id })))
