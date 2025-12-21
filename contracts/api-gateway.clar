;; api-gateway - Clarity 4
;; API gateway for external system integration

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ENDPOINT-NOT-FOUND (err u101))
(define-constant ERR-RATE-LIMIT-EXCEEDED (err u102))
(define-constant ERR-INVALID-API-KEY (err u103))

(define-map api-endpoints (string-ascii 100)
  {
    endpoint-owner: principal,
    endpoint-url: (string-utf8 256),
    method: (string-ascii 10),
    is-active: bool,
    rate-limit: uint,
    created-at: uint
  }
)

(define-map api-keys (buff 64)
  {
    key-owner: principal,
    permissions: (list 10 (string-ascii 50)),
    created-at: uint,
    expires-at: uint,
    is-active: bool,
    request-count: uint
  }
)

(define-map api-requests uint
  {
    api-key-hash: (buff 64),
    endpoint: (string-ascii 100),
    request-data-hash: (buff 64),
    response-hash: (buff 64),
    status-code: uint,
    timestamp: uint
  }
)

(define-map rate-limiting { api-key-hash: (buff 64), window-start: uint }
  { request-count: uint }
)

(define-data-var request-counter uint u0)
(define-data-var rate-limit-window uint u3600) ;; 1 hour

(define-public (register-endpoint
    (endpoint-id (string-ascii 100))
    (endpoint-url (string-utf8 256))
    (method (string-ascii 10))
    (rate-limit uint))
  (ok (map-set api-endpoints endpoint-id
    {
      endpoint-owner: tx-sender,
      endpoint-url: endpoint-url,
      method: method,
      is-active: true,
      rate-limit: rate-limit,
      created-at: stacks-block-time
    })))

(define-public (create-api-key
    (key-hash (buff 64))
    (permissions (list 10 (string-ascii 50)))
    (duration uint))
  (ok (map-set api-keys key-hash
    {
      key-owner: tx-sender,
      permissions: permissions,
      created-at: stacks-block-time,
      expires-at: (+ stacks-block-time duration),
      is-active: true,
      request-count: u0
    })))

(define-public (log-api-request
    (api-key-hash (buff 64))
    (endpoint (string-ascii 100))
    (request-data-hash (buff 64))
    (response-hash (buff 64))
    (status-code uint))
  (let ((key-info (unwrap! (map-get? api-keys api-key-hash) ERR-INVALID-API-KEY))
        (request-id (+ (var-get request-counter) u1)))
    (asserts! (get is-active key-info) ERR-INVALID-API-KEY)
    (asserts! (< stacks-block-time (get expires-at key-info)) ERR-INVALID-API-KEY)
    (try! (check-rate-limit api-key-hash))
    (map-set api-requests request-id
      {
        api-key-hash: api-key-hash,
        endpoint: endpoint,
        request-data-hash: request-data-hash,
        response-hash: response-hash,
        status-code: status-code,
        timestamp: stacks-block-time
      })
    (map-set api-keys api-key-hash
      (merge key-info { request-count: (+ (get request-count key-info) u1) }))
    (var-set request-counter request-id)
    (ok request-id)))

(define-private (check-rate-limit (api-key-hash (buff 64)))
  (let ((window-start (/ stacks-block-time (var-get rate-limit-window)))
        (current-count (default-to
                         { request-count: u0 }
                         (map-get? rate-limiting { api-key-hash: api-key-hash, window-start: window-start }))))
    (asserts! (< (get request-count current-count) u100) ERR-RATE-LIMIT-EXCEEDED)
    (ok (map-set rate-limiting { api-key-hash: api-key-hash, window-start: window-start }
      { request-count: (+ (get request-count current-count) u1) }))))

(define-public (revoke-api-key (key-hash (buff 64)))
  (let ((key-info (unwrap! (map-get? api-keys key-hash) ERR-INVALID-API-KEY)))
    (asserts! (is-eq tx-sender (get key-owner key-info)) ERR-NOT-AUTHORIZED)
    (ok (map-set api-keys key-hash (merge key-info { is-active: false })))))

(define-read-only (get-endpoint (endpoint-id (string-ascii 100)))
  (ok (map-get? api-endpoints endpoint-id)))

(define-read-only (get-api-key-info (key-hash (buff 64)))
  (ok (map-get? api-keys key-hash)))

(define-read-only (get-request (request-id uint))
  (ok (map-get? api-requests request-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-request-id (request-id uint))
  (ok (int-to-ascii request-id)))

(define-read-only (parse-request-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
