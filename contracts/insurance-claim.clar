;; insurance-claim - Clarity 4
;; Insurance claim processing and management system

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CLAIM-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-PROCESSED (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))

(define-map insurance-claims uint
  {
    claimant: principal,
    provider: principal,
    insurer: principal,
    claim-amount: uint,
    approved-amount: (optional uint),
    claim-type: (string-ascii 50),
    diagnosis-codes: (list 5 (string-ascii 10)),
    procedure-codes: (list 5 (string-ascii 10)),
    filed-at: uint,
    processed-at: (optional uint),
    status: (string-ascii 20)
  }
)

(define-map claim-documents uint
  {
    claim-id: uint,
    document-type: (string-ascii 50),
    document-hash: (buff 64),
    uploaded-by: principal,
    uploaded-at: uint
  }
)

(define-map claim-adjudications uint
  {
    claim-id: uint,
    adjudicator: principal,
    decision: (string-ascii 20),
    reason: (string-utf8 500),
    approved-amount: uint,
    adjudicated-at: uint
  }
)

(define-map claim-appeals uint
  {
    original-claim-id: uint,
    appellant: principal,
    appeal-reason: (string-utf8 500),
    supporting-docs: (list 5 (buff 64)),
    filed-at: uint,
    appeal-status: (string-ascii 20)
  }
)

(define-data-var claim-counter uint u0)
(define-data-var document-counter uint u0)
(define-data-var adjudication-counter uint u0)
(define-data-var appeal-counter uint u0)

(define-public (file-claim
    (provider principal)
    (insurer principal)
    (claim-amount uint)
    (claim-type (string-ascii 50))
    (diagnosis-codes (list 5 (string-ascii 10)))
    (procedure-codes (list 5 (string-ascii 10))))
  (let ((claim-id (+ (var-get claim-counter) u1)))
    (asserts! (> claim-amount u0) ERR-INVALID-AMOUNT)
    (map-set insurance-claims claim-id
      {
        claimant: tx-sender,
        provider: provider,
        insurer: insurer,
        claim-amount: claim-amount,
        approved-amount: none,
        claim-type: claim-type,
        diagnosis-codes: diagnosis-codes,
        procedure-codes: procedure-codes,
        filed-at: stacks-block-time,
        processed-at: none,
        status: "pending"
      })
    (var-set claim-counter claim-id)
    (ok claim-id)))

(define-public (upload-claim-document
    (claim-id uint)
    (document-type (string-ascii 50))
    (document-hash (buff 64)))
  (let ((claim (unwrap! (map-get? insurance-claims claim-id) ERR-CLAIM-NOT-FOUND))
        (document-id (+ (var-get document-counter) u1)))
    (asserts! (or (is-eq tx-sender (get claimant claim))
                  (is-eq tx-sender (get provider claim))) ERR-NOT-AUTHORIZED)
    (map-set claim-documents document-id
      {
        claim-id: claim-id,
        document-type: document-type,
        document-hash: document-hash,
        uploaded-by: tx-sender,
        uploaded-at: stacks-block-time
      })
    (var-set document-counter document-id)
    (ok document-id)))

(define-public (adjudicate-claim
    (claim-id uint)
    (decision (string-ascii 20))
    (reason (string-utf8 500))
    (approved-amount uint))
  (let ((claim (unwrap! (map-get? insurance-claims claim-id) ERR-CLAIM-NOT-FOUND))
        (adjudication-id (+ (var-get adjudication-counter) u1)))
    (asserts! (is-eq tx-sender (get insurer claim)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status claim) "pending") ERR-ALREADY-PROCESSED)
    (map-set claim-adjudications adjudication-id
      {
        claim-id: claim-id,
        adjudicator: tx-sender,
        decision: decision,
        reason: reason,
        approved-amount: approved-amount,
        adjudicated-at: stacks-block-time
      })
    (map-set insurance-claims claim-id
      (merge claim {
        approved-amount: (some approved-amount),
        processed-at: (some stacks-block-time),
        status: decision
      }))
    (var-set adjudication-counter adjudication-id)
    (ok adjudication-id)))

(define-public (file-appeal
    (claim-id uint)
    (appeal-reason (string-utf8 500))
    (supporting-docs (list 5 (buff 64))))
  (let ((claim (unwrap! (map-get? insurance-claims claim-id) ERR-CLAIM-NOT-FOUND))
        (appeal-id (+ (var-get appeal-counter) u1)))
    (asserts! (is-eq tx-sender (get claimant claim)) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq (get status claim) "pending")) ERR-NOT-AUTHORIZED)
    (map-set claim-appeals appeal-id
      {
        original-claim-id: claim-id,
        appellant: tx-sender,
        appeal-reason: appeal-reason,
        supporting-docs: supporting-docs,
        filed-at: stacks-block-time,
        appeal-status: "pending"
      })
    (var-set appeal-counter appeal-id)
    (ok appeal-id)))

(define-public (update-claim-status
    (claim-id uint)
    (new-status (string-ascii 20)))
  (let ((claim (unwrap! (map-get? insurance-claims claim-id) ERR-CLAIM-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get insurer claim)) ERR-NOT-AUTHORIZED)
    (ok (map-set insurance-claims claim-id
      (merge claim { status: new-status })))))

(define-read-only (get-claim (claim-id uint))
  (ok (map-get? insurance-claims claim-id)))

(define-read-only (get-claim-document (document-id uint))
  (ok (map-get? claim-documents document-id)))

(define-read-only (get-adjudication (adjudication-id uint))
  (ok (map-get? claim-adjudications adjudication-id)))

(define-read-only (get-appeal (appeal-id uint))
  (ok (map-get? claim-appeals appeal-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-claim-id (claim-id uint))
  (ok (int-to-ascii claim-id)))

(define-read-only (parse-claim-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
