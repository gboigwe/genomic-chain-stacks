;; genome-provenance - Clarity 4
;; Track chain of custody for genomic data

(define-constant ERR-EVENT-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-CHAIN (err u102))

(define-map provenance-events uint
  {
    data-id: uint,
    actor: principal,
    action: (string-ascii 50),
    timestamp: uint,
    location: (string-ascii 100),
    previous-event-id: (optional uint),
    metadata-hash: (buff 64),
    verified: bool
  }
)

(define-map custody-chains uint
  {
    data-id: uint,
    chain-start: uint,
    chain-length: uint,
    current-custodian: principal,
    last-transfer: uint,
    is-complete: bool
  }
)

(define-map transfer-records uint
  {
    data-id: uint,
    from-party: principal,
    to-party: principal,
    transfer-reason: (string-utf8 300),
    transfer-date: uint,
    approval-required: bool,
    approved-by: (optional principal)
  }
)

(define-map data-lineage uint
  {
    data-id: uint,
    parent-data-id: (optional uint),
    derivation-method: (string-ascii 100),
    created-at: uint,
    created-by: principal,
    lineage-depth: uint
  }
)

(define-map provenance-attestations uint
  {
    event-id: uint,
    attestor: principal,
    attestation-type: (string-ascii 50),
    attestation-data: (buff 128),
    attested-at: uint,
    is-valid: bool
  }
)

(define-map integrity-checks uint
  {
    data-id: uint,
    check-type: (string-ascii 50),
    expected-hash: (buff 64),
    actual-hash: (buff 64),
    matches: bool,
    checked-at: uint,
    checked-by: principal
  }
)

(define-data-var event-counter uint u0)
(define-data-var chain-counter uint u0)
(define-data-var transfer-counter uint u0)
(define-data-var lineage-counter uint u0)
(define-data-var attestation-counter uint u0)
(define-data-var check-counter uint u0)

(define-public (log-event
    (data-id uint)
    (action (string-ascii 50))
    (location (string-ascii 100))
    (previous-event-id (optional uint))
    (metadata-hash (buff 64)))
  (let ((event-id (+ (var-get event-counter) u1)))
    (map-set provenance-events event-id
      {
        data-id: data-id,
        actor: tx-sender,
        action: action,
        timestamp: stacks-block-time,
        location: location,
        previous-event-id: previous-event-id,
        metadata-hash: metadata-hash,
        verified: false
      })
    (var-set event-counter event-id)
    (ok event-id)))

(define-public (initialize-custody-chain
    (data-id uint))
  (let ((custody-chain-id (+ (var-get chain-counter) u1))
        (event-id (var-get event-counter)))
    (map-set custody-chains custody-chain-id
      {
        data-id: data-id,
        chain-start: event-id,
        chain-length: u1,
        current-custodian: tx-sender,
        last-transfer: stacks-block-time,
        is-complete: false
      })
    (var-set chain-counter custody-chain-id)
    (ok custody-chain-id)))

(define-public (transfer-custody
    (data-id uint)
    (to-party principal)
    (transfer-reason (string-utf8 300))
    (approval-required bool))
  (let ((transfer-id (+ (var-get transfer-counter) u1)))
    (map-set transfer-records transfer-id
      {
        data-id: data-id,
        from-party: tx-sender,
        to-party: to-party,
        transfer-reason: transfer-reason,
        transfer-date: stacks-block-time,
        approval-required: approval-required,
        approved-by: (if approval-required none (some tx-sender))
      })
    (var-set transfer-counter transfer-id)
    (ok transfer-id)))

(define-public (record-data-lineage
    (data-id uint)
    (parent-data-id (optional uint))
    (derivation-method (string-ascii 100))
    (lineage-depth uint))
  (let ((lineage-id (+ (var-get lineage-counter) u1)))
    (map-set data-lineage lineage-id
      {
        data-id: data-id,
        parent-data-id: parent-data-id,
        derivation-method: derivation-method,
        created-at: stacks-block-time,
        created-by: tx-sender,
        lineage-depth: lineage-depth
      })
    (var-set lineage-counter lineage-id)
    (ok lineage-id)))

(define-public (attest-provenance
    (event-id uint)
    (attestation-type (string-ascii 50))
    (attestation-data (buff 128)))
  (let ((attestation-id (+ (var-get attestation-counter) u1)))
    (asserts! (is-some (map-get? provenance-events event-id)) ERR-EVENT-NOT-FOUND)
    (map-set provenance-attestations attestation-id
      {
        event-id: event-id,
        attestor: tx-sender,
        attestation-type: attestation-type,
        attestation-data: attestation-data,
        attested-at: stacks-block-time,
        is-valid: true
      })
    (var-set attestation-counter attestation-id)
    (ok attestation-id)))

(define-public (verify-integrity
    (data-id uint)
    (check-type (string-ascii 50))
    (expected-hash (buff 64))
    (actual-hash (buff 64)))
  (let ((check-id (+ (var-get check-counter) u1))
        (matches (is-eq expected-hash actual-hash)))
    (map-set integrity-checks check-id
      {
        data-id: data-id,
        check-type: check-type,
        expected-hash: expected-hash,
        actual-hash: actual-hash,
        matches: matches,
        checked-at: stacks-block-time,
        checked-by: tx-sender
      })
    (var-set check-counter check-id)
    (ok check-id)))

(define-public (complete-custody-chain (custody-chain-id uint))
  (let ((chain (unwrap! (map-get? custody-chains custody-chain-id) ERR-INVALID-CHAIN)))
    (asserts! (is-eq tx-sender (get current-custodian chain)) ERR-NOT-AUTHORIZED)
    (ok (map-set custody-chains custody-chain-id
      (merge chain { is-complete: true })))))

(define-read-only (get-event (event-id uint))
  (ok (map-get? provenance-events event-id)))

(define-read-only (get-custody-chain (custody-chain-id uint))
  (ok (map-get? custody-chains custody-chain-id)))

(define-read-only (get-transfer-record (transfer-id uint))
  (ok (map-get? transfer-records transfer-id)))

(define-read-only (get-data-lineage (lineage-id uint))
  (ok (map-get? data-lineage lineage-id)))

(define-read-only (get-attestation (attestation-id uint))
  (ok (map-get? provenance-attestations attestation-id)))

(define-read-only (get-integrity-check (check-id uint))
  (ok (map-get? integrity-checks check-id)))

(define-read-only (validate-actor (actor principal))
  (principal-destruct? actor))

(define-read-only (format-event-id (event-id uint))
  (ok (int-to-ascii event-id)))

(define-read-only (parse-event-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
