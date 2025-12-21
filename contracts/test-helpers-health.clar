;; test-helpers-health - Clarity 4
;; Testing utility functions and mock data helpers for health platform

(define-constant ERR-INVALID-INPUT (err u100))
(define-constant ERR-TEST-FAILED (err u101))

(define-map test-scenarios uint
  {
    scenario-name: (string-utf8 100),
    test-data: (buff 128),
    expected-result: (buff 128),
    created-by: principal,
    created-at: uint
  }
)

(define-map test-assertions uint
  {
    assertion-type: (string-ascii 50),
    expected-value: uint,
    actual-value: uint,
    passed: bool,
    tested-at: uint
  }
)

(define-map mock-addresses principal
  {
    address-type: (string-ascii 50),
    display-name: (string-utf8 100),
    is-test-account: bool,
    created-at: uint
  }
)

(define-map test-execution-logs uint
  {
    test-name: (string-utf8 100),
    executor: principal,
    status: (string-ascii 20),
    execution-time: uint,
    error-message: (optional (string-utf8 500))
  }
)

(define-data-var scenario-counter uint u0)
(define-data-var assertion-counter uint u0)
(define-data-var log-counter uint u0)

(define-public (create-test-scenario
    (scenario-name (string-utf8 100))
    (test-data (buff 128))
    (expected-result (buff 128)))
  (let ((scenario-id (+ (var-get scenario-counter) u1)))
    (map-set test-scenarios scenario-id
      {
        scenario-name: scenario-name,
        test-data: test-data,
        expected-result: expected-result,
        created-by: tx-sender,
        created-at: stacks-block-time
      })
    (var-set scenario-counter scenario-id)
    (ok scenario-id)))

(define-public (assert-equals
    (expected uint)
    (actual uint)
    (assertion-type (string-ascii 50)))
  (let ((assertion-id (+ (var-get assertion-counter) u1))
        (passed (is-eq expected actual)))
    (map-set test-assertions assertion-id
      {
        assertion-type: assertion-type,
        expected-value: expected,
        actual-value: actual,
        passed: passed,
        tested-at: stacks-block-time
      })
    (var-set assertion-counter assertion-id)
    (if passed
        (ok true)
        ERR-TEST-FAILED)))

(define-public (register-mock-address
    (address principal)
    (address-type (string-ascii 50))
    (display-name (string-utf8 100)))
  (ok (map-set mock-addresses address
    {
      address-type: address-type,
      display-name: display-name,
      is-test-account: true,
      created-at: stacks-block-time
    })))

(define-public (log-test-execution
    (test-name (string-utf8 100))
    (status (string-ascii 20))
    (execution-time uint)
    (error-message (optional (string-utf8 500))))
  (let ((log-id (+ (var-get log-counter) u1)))
    (map-set test-execution-logs log-id
      {
        test-name: test-name,
        executor: tx-sender,
        status: status,
        execution-time: execution-time,
        error-message: error-message
      })
    (var-set log-counter log-id)
    (ok log-id)))

(define-read-only (get-test-scenario (scenario-id uint))
  (ok (map-get? test-scenarios scenario-id)))

(define-read-only (get-assertion (assertion-id uint))
  (ok (map-get? test-assertions assertion-id)))

(define-read-only (get-mock-address (address principal))
  (ok (map-get? mock-addresses address)))

(define-read-only (get-test-log (log-id uint))
  (ok (map-get? test-execution-logs log-id)))

(define-read-only (generate-test-hash (input uint))
  (ok (sha256 (unwrap-panic (to-consensus-buff? input)))))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-test-id (test-id uint))
  (ok (int-to-ascii test-id)))

(define-read-only (parse-test-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
