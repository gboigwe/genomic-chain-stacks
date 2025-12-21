;; oracle-health-data - Clarity 4
;; Oracle service for external health data integration

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ORACLE-NOT-FOUND (err u101))
(define-constant ERR-REQUEST-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-FULFILLED (err u103))

(define-map oracle-providers principal
  {
    provider-name: (string-utf8 100),
    data-sources: (list 10 (string-ascii 50)),
    total-requests: uint,
    successful-requests: uint,
    reliability-score: uint,
    is-active: bool
  }
)

(define-map data-requests uint
  {
    requester: principal,
    data-type: (string-ascii 50),
    query-parameters: (buff 128),
    requested-at: uint,
    oracle-provider: (optional principal),
    is-fulfilled: bool,
    fulfilled-at: (optional uint)
  }
)

(define-map data-responses uint
  {
    request-id: uint,
    response-data-hash: (buff 64),
    provider: principal,
    confidence-score: uint,
    timestamp: uint,
    verification-proof: (buff 64)
  }
)

(define-map oracle-reputation principal
  {
    total-responses: uint,
    accurate-responses: uint,
    average-response-time: uint,
    disputes: uint
  }
)

(define-data-var request-counter uint u0)
(define-data-var response-counter uint u0)
(define-data-var min-confidence-threshold uint u80)

(define-public (register-oracle-provider
    (provider-name (string-utf8 100))
    (data-sources (list 10 (string-ascii 50))))
  (ok (map-set oracle-providers tx-sender
    {
      provider-name: provider-name,
      data-sources: data-sources,
      total-requests: u0,
      successful-requests: u0,
      reliability-score: u50,
      is-active: true
    })))

(define-public (request-data
    (data-type (string-ascii 50))
    (query-parameters (buff 128)))
  (let ((request-id (+ (var-get request-counter) u1)))
    (map-set data-requests request-id
      {
        requester: tx-sender,
        data-type: data-type,
        query-parameters: query-parameters,
        requested-at: stacks-block-time,
        oracle-provider: none,
        is-fulfilled: false,
        fulfilled-at: none
      })
    (var-set request-counter request-id)
    (ok request-id)))

(define-public (fulfill-request
    (request-id uint)
    (response-data-hash (buff 64))
    (confidence-score uint)
    (verification-proof (buff 64)))
  (let ((request (unwrap! (map-get? data-requests request-id) ERR-REQUEST-NOT-FOUND))
        (provider (unwrap! (map-get? oracle-providers tx-sender) ERR-NOT-AUTHORIZED))
        (response-id (+ (var-get response-counter) u1)))
    (asserts! (get is-active provider) ERR-NOT-AUTHORIZED)
    (asserts! (not (get is-fulfilled request)) ERR-ALREADY-FULFILLED)
    (asserts! (>= confidence-score (var-get min-confidence-threshold)) (err u105))
    (map-set data-responses response-id
      {
        request-id: request-id,
        response-data-hash: response-data-hash,
        provider: tx-sender,
        confidence-score: confidence-score,
        timestamp: stacks-block-time,
        verification-proof: verification-proof
      })
    (map-set data-requests request-id
      (merge request {
        oracle-provider: (some tx-sender),
        is-fulfilled: true,
        fulfilled-at: (some stacks-block-time)
      }))
    (update-oracle-stats tx-sender)
    (var-set response-counter response-id)
    (ok response-id)))

(define-public (verify-response (response-id uint) (is-accurate bool))
  (let ((response (unwrap! (map-get? data-responses response-id) ERR-REQUEST-NOT-FOUND)))
    (update-reputation (get provider response) is-accurate)
    (ok true)))

(define-private (update-oracle-stats (oracle principal))
  (let ((provider (unwrap! (map-get? oracle-providers oracle) ERR-NOT-AUTHORIZED)))
    (map-set oracle-providers oracle
      (merge provider {
        total-requests: (+ (get total-requests provider) u1),
        successful-requests: (+ (get successful-requests provider) u1),
        reliability-score: (/ (* (+ (get successful-requests provider) u1) u100) (+ (get total-requests provider) u1))
      }))
    (ok true)))

(define-private (update-reputation (oracle principal) (is-accurate bool))
  (let ((rep (default-to
               { total-responses: u0, accurate-responses: u0, average-response-time: u0, disputes: u0 }
               (map-get? oracle-reputation oracle))))
    (map-set oracle-reputation oracle
      {
        total-responses: (+ (get total-responses rep) u1),
        accurate-responses: (if is-accurate (+ (get accurate-responses rep) u1) (get accurate-responses rep)),
        average-response-time: (get average-response-time rep),
        disputes: (if is-accurate (get disputes rep) (+ (get disputes rep) u1))
      })
    (ok true)))

(define-read-only (get-oracle-provider (provider principal))
  (ok (map-get? oracle-providers provider)))

(define-read-only (get-data-request (request-id uint))
  (ok (map-get? data-requests request-id)))

(define-read-only (get-data-response (response-id uint))
  (ok (map-get? data-responses response-id)))

(define-read-only (get-oracle-reputation (oracle principal))
  (ok (map-get? oracle-reputation oracle)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-request-id (request-id uint))
  (ok (int-to-ascii request-id)))

(define-read-only (parse-request-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
