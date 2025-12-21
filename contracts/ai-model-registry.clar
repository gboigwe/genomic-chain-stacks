;; ai-model-registry - Clarity 4
;; Registry for AI/ML models trained on genomic data

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-MODEL-NOT-FOUND (err u101))
(define-constant ERR-INVALID-ACCURACY (err u102))

(define-map ai-models uint
  {
    model-owner: principal,
    model-name: (string-utf8 200),
    model-type: (string-ascii 50),
    model-hash: (buff 64),
    training-data-hash: (buff 64),
    accuracy-score: uint,
    validation-score: uint,
    created-at: uint,
    is-verified: bool,
    inference-count: uint
  }
)

(define-map model-performance { model-id: uint, metric: (string-ascii 50) }
  { value: uint, recorded-at: uint }
)

(define-map inference-logs uint
  {
    model-id: uint,
    requester: principal,
    input-hash: (buff 64),
    output-hash: (buff 64),
    timestamp: uint,
    confidence-score: uint
  }
)

(define-data-var model-counter uint u0)
(define-data-var inference-counter uint u0)

(define-public (register-model
    (model-name (string-utf8 200))
    (model-type (string-ascii 50))
    (model-hash (buff 64))
    (training-data-hash (buff 64))
    (accuracy-score uint)
    (validation-score uint))
  (let ((model-id (+ (var-get model-counter) u1)))
    (asserts! (<= accuracy-score u100) ERR-INVALID-ACCURACY)
    (asserts! (<= validation-score u100) ERR-INVALID-ACCURACY)
    (map-set ai-models model-id
      {
        model-owner: tx-sender,
        model-name: model-name,
        model-type: model-type,
        model-hash: model-hash,
        training-data-hash: training-data-hash,
        accuracy-score: accuracy-score,
        validation-score: validation-score,
        created-at: stacks-block-time,
        is-verified: false,
        inference-count: u0
      })
    (var-set model-counter model-id)
    (ok model-id)))

(define-public (log-inference
    (model-id uint)
    (input-hash (buff 64))
    (output-hash (buff 64))
    (confidence-score uint))
  (let ((model (unwrap! (map-get? ai-models model-id) ERR-MODEL-NOT-FOUND))
        (inference-id (+ (var-get inference-counter) u1)))
    (asserts! (<= confidence-score u100) ERR-INVALID-ACCURACY)
    (map-set inference-logs inference-id
      {
        model-id: model-id,
        requester: tx-sender,
        input-hash: input-hash,
        output-hash: output-hash,
        timestamp: stacks-block-time,
        confidence-score: confidence-score
      })
    (map-set ai-models model-id
      (merge model { inference-count: (+ (get inference-count model) u1) }))
    (var-set inference-counter inference-id)
    (ok inference-id)))

(define-public (verify-model (model-id uint))
  (let ((model (unwrap! (map-get? ai-models model-id) ERR-MODEL-NOT-FOUND)))
    (ok (map-set ai-models model-id (merge model { is-verified: true })))))

(define-public (record-performance
    (model-id uint)
    (metric (string-ascii 50))
    (value uint))
  (let ((model (unwrap! (map-get? ai-models model-id) ERR-MODEL-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get model-owner model)) ERR-NOT-AUTHORIZED)
    (ok (map-set model-performance { model-id: model-id, metric: metric }
      { value: value, recorded-at: stacks-block-time }))))

(define-read-only (get-model (model-id uint))
  (ok (map-get? ai-models model-id)))

(define-read-only (get-performance (model-id uint) (metric (string-ascii 50)))
  (ok (map-get? model-performance { model-id: model-id, metric: metric })))

(define-read-only (get-inference-log (inference-id uint))
  (ok (map-get? inference-logs inference-id)))

(define-read-only (validate-owner (owner principal))
  (principal-destruct? owner))

(define-read-only (format-model-id (model-id uint))
  (ok (int-to-ascii model-id)))

(define-read-only (parse-model-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
