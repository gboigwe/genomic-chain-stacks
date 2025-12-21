;; genome-provenance.clar - Clarity 4
;; Data lineage tracking for genomic datasets

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ENTRY-NOT-FOUND (err u101))

(define-data-var entry-counter uint u0)

(define-map provenance-entries
  { entry-id: uint }
  {
    dataset-id: uint,
    action: (string-ascii 50),
    actor: principal,
    timestamp: uint,
    previous-hash: (buff 32),
    current-hash: (buff 32),
    details: (string-utf8 256)
  }
)

(define-public (record-provenance
    (dataset-id uint)
    (action (string-ascii 50))
    (previous-hash (buff 32))
    (current-hash (buff 32))
    (details (string-utf8 256)))
  (let
    ((new-entry-id (+ (var-get entry-counter) u1)))
    (map-set provenance-entries { entry-id: new-entry-id }
      {
        dataset-id: dataset-id,
        action: action,
        actor: tx-sender,
        timestamp: stacks-block-time,
        previous-hash: previous-hash,
        current-hash: current-hash,
        details: details
      })
    (var-set entry-counter new-entry-id)
    (ok new-entry-id)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-actor (actor principal))
  (principal-destruct? actor))

;; Clarity 4: int-to-ascii
(define-read-only (format-entry-id (entry-id uint))
  (ok (int-to-ascii entry-id)))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-height)
  (ok burn-block-height))

(define-read-only (get-provenance-entry (entry-id uint))
  (ok (map-get? provenance-entries { entry-id: entry-id })))
