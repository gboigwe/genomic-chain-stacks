;; homomorphic-compute - Clarity 4
;; Homomorphic encryption computation registry

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-COMPUTATION-NOT-FOUND (err u101))
(define-constant ERR-INVALID-PROOF (err u102))

(define-map encrypted-computations uint
  {
    requester: principal,
    encrypted-input-hash: (buff 64),
    computation-type: (string-ascii 50),
    public-key-hash: (buff 64),
    encrypted-result-hash: (optional (buff 64)),
    created-at: uint,
    completed-at: (optional uint),
    is-verified: bool
  }
)

(define-map computation-providers principal
  {
    provider-name: (string-utf8 100),
    public-key-hash: (buff 64),
    computation-types: (list 10 (string-ascii 50)),
    total-computations: uint,
    success-rate: uint,
    is-active: bool
  }
)

(define-map computation-proofs uint
  {
    computation-id: uint,
    proof-hash: (buff 64),
    verifier: principal,
    verified-at: uint,
    is-valid: bool
  }
)

(define-data-var computation-counter uint u0)
(define-data-var proof-counter uint u0)

(define-public (register-provider
    (provider-name (string-utf8 100))
    (public-key-hash (buff 64))
    (computation-types (list 10 (string-ascii 50))))
  (ok (map-set computation-providers tx-sender
    {
      provider-name: provider-name,
      public-key-hash: public-key-hash,
      computation-types: computation-types,
      total-computations: u0,
      success-rate: u100,
      is-active: true
    })))

(define-public (request-computation
    (encrypted-input-hash (buff 64))
    (computation-type (string-ascii 50))
    (public-key-hash (buff 64)))
  (let ((computation-id (+ (var-get computation-counter) u1)))
    (map-set encrypted-computations computation-id
      {
        requester: tx-sender,
        encrypted-input-hash: encrypted-input-hash,
        computation-type: computation-type,
        public-key-hash: public-key-hash,
        encrypted-result-hash: none,
        created-at: stacks-block-time,
        completed-at: none,
        is-verified: false
      })
    (var-set computation-counter computation-id)
    (ok computation-id)))

(define-public (submit-result
    (computation-id uint)
    (encrypted-result-hash (buff 64)))
  (let ((computation (unwrap! (map-get? encrypted-computations computation-id) ERR-COMPUTATION-NOT-FOUND))
        (provider (unwrap! (map-get? computation-providers tx-sender) ERR-NOT-AUTHORIZED)))
    (asserts! (get is-active provider) ERR-NOT-AUTHORIZED)
    (ok (map-set encrypted-computations computation-id
      (merge computation {
        encrypted-result-hash: (some encrypted-result-hash),
        completed-at: (some stacks-block-time)
      })))))

(define-public (verify-computation
    (computation-id uint)
    (proof-hash (buff 64)))
  (let ((computation (unwrap! (map-get? encrypted-computations computation-id) ERR-COMPUTATION-NOT-FOUND))
        (proof-id (+ (var-get proof-counter) u1)))
    (map-set computation-proofs proof-id
      {
        computation-id: computation-id,
        proof-hash: proof-hash,
        verifier: tx-sender,
        verified-at: stacks-block-time,
        is-valid: true
      })
    (map-set encrypted-computations computation-id
      (merge computation { is-verified: true }))
    (var-set proof-counter proof-id)
    (ok proof-id)))

(define-read-only (get-computation (computation-id uint))
  (ok (map-get? encrypted-computations computation-id)))

(define-read-only (get-provider (provider principal))
  (ok (map-get? computation-providers provider)))

(define-read-only (get-proof (proof-id uint))
  (ok (map-get? computation-proofs proof-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-computation-id (computation-id uint))
  (ok (int-to-ascii computation-id)))

(define-read-only (parse-computation-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
