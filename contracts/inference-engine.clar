;; inference-engine - Clarity 4
;; ML inference engine for genomic and health predictions

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-MODEL-NOT-FOUND (err u101))
(define-constant ERR-INFERENCE-NOT-FOUND (err u102))
(define-constant ERR-INVALID-INPUT (err u103))

(define-map inference-models uint
  {
    model-name: (string-utf8 200),
    model-hash: (buff 64),
    model-type: (string-ascii 50),
    input-schema-hash: (buff 64),
    output-schema-hash: (buff 64),
    accuracy: uint,
    deployed-by: principal,
    deployed-at: uint,
    is-active: bool
  }
)

(define-map inference-requests uint
  {
    model-id: uint,
    requester: principal,
    input-data-hash: (buff 64),
    result-hash: (optional (buff 64)),
    confidence-score: (optional uint),
    requested-at: uint,
    completed-at: (optional uint),
    status: (string-ascii 20)
  }
)

(define-map model-performance uint
  {
    model-id: uint,
    total-inferences: uint,
    average-confidence: uint,
    average-latency: uint,
    last-updated: uint
  }
)

(define-map prediction-cache (buff 64)
  {
    model-id: uint,
    input-hash: (buff 64),
    result-hash: (buff 64),
    confidence: uint,
    cached-at: uint,
    hit-count: uint
  }
)

(define-map model-validators principal
  {
    validator-name: (string-utf8 100),
    specialization: (string-ascii 50),
    models-validated: uint,
    is-active: bool
  }
)

(define-data-var model-counter uint u0)
(define-data-var inference-counter uint u0)
(define-data-var min-confidence-threshold uint u70)

(define-public (deploy-model
    (model-name (string-utf8 200))
    (model-hash (buff 64))
    (model-type (string-ascii 50))
    (input-schema-hash (buff 64))
    (output-schema-hash (buff 64))
    (accuracy uint))
  (let ((model-id (+ (var-get model-counter) u1)))
    (map-set inference-models model-id
      {
        model-name: model-name,
        model-hash: model-hash,
        model-type: model-type,
        input-schema-hash: input-schema-hash,
        output-schema-hash: output-schema-hash,
        accuracy: accuracy,
        deployed-by: tx-sender,
        deployed-at: stacks-block-time,
        is-active: true
      })
    (map-set model-performance model-id
      {
        model-id: model-id,
        total-inferences: u0,
        average-confidence: u0,
        average-latency: u0,
        last-updated: stacks-block-time
      })
    (var-set model-counter model-id)
    (ok model-id)))

(define-public (request-inference
    (model-id uint)
    (input-data-hash (buff 64)))
  (let ((model (unwrap! (map-get? inference-models model-id) ERR-MODEL-NOT-FOUND))
        (inference-id (+ (var-get inference-counter) u1)))
    (asserts! (get is-active model) ERR-MODEL-NOT-FOUND)
    (map-set inference-requests inference-id
      {
        model-id: model-id,
        requester: tx-sender,
        input-data-hash: input-data-hash,
        result-hash: none,
        confidence-score: none,
        requested-at: stacks-block-time,
        completed-at: none,
        status: "pending"
      })
    (var-set inference-counter inference-id)
    (ok inference-id)))

(define-public (submit-inference-result
    (inference-id uint)
    (result-hash (buff 64))
    (confidence-score uint))
  (let ((request (unwrap! (map-get? inference-requests inference-id) ERR-INFERENCE-NOT-FOUND))
        (model (unwrap! (map-get? inference-models (get model-id request)) ERR-MODEL-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get deployed-by model)) ERR-NOT-AUTHORIZED)
    (map-set inference-requests inference-id
      (merge request {
        result-hash: (some result-hash),
        confidence-score: (some confidence-score),
        completed-at: (some stacks-block-time),
        status: "completed"
      }))
    (cache-prediction (get input-data-hash request) result-hash (get model-id request) confidence-score)
    (update-model-performance (get model-id request) confidence-score)
    (ok true)))

(define-public (register-validator
    (validator-name (string-utf8 100))
    (specialization (string-ascii 50)))
  (ok (map-set model-validators tx-sender
    {
      validator-name: validator-name,
      specialization: specialization,
      models-validated: u0,
      is-active: true
    })))

(define-public (deactivate-model (model-id uint))
  (let ((model (unwrap! (map-get? inference-models model-id) ERR-MODEL-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get deployed-by model)) ERR-NOT-AUTHORIZED)
    (ok (map-set inference-models model-id
      (merge model { is-active: false })))))

(define-private (cache-prediction
    (input-hash (buff 64))
    (result-hash (buff 64))
    (model-id uint)
    (confidence uint))
  (let ((cache-key input-hash))
    (map-set prediction-cache cache-key
      {
        model-id: model-id,
        input-hash: input-hash,
        result-hash: result-hash,
        confidence: confidence,
        cached-at: stacks-block-time,
        hit-count: u0
      })
    true))

(define-private (update-model-performance (model-id uint) (confidence uint))
  (let ((perf (unwrap! (map-get? model-performance model-id) ERR-MODEL-NOT-FOUND)))
    (map-set model-performance model-id
      {
        model-id: model-id,
        total-inferences: (+ (get total-inferences perf) u1),
        average-confidence: (/ (+ (* (get average-confidence perf) (get total-inferences perf)) confidence)
                               (+ (get total-inferences perf) u1)),
        average-latency: (get average-latency perf),
        last-updated: stacks-block-time
      })
    (ok true)))

(define-read-only (get-model (model-id uint))
  (ok (map-get? inference-models model-id)))

(define-read-only (get-inference-request (inference-id uint))
  (ok (map-get? inference-requests inference-id)))

(define-read-only (get-model-performance (model-id uint))
  (ok (map-get? model-performance model-id)))

(define-read-only (get-cached-prediction (input-hash (buff 64)))
  (ok (map-get? prediction-cache input-hash)))

(define-read-only (get-validator (validator principal))
  (ok (map-get? model-validators validator)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-model-id (model-id uint))
  (ok (int-to-ascii model-id)))

(define-read-only (parse-model-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
