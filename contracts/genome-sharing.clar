;; genome-sharing.clar - Clarity 4
;; Data sharing agreements and permissions

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-AGREEMENT-EXISTS (err u101))
(define-constant ERR-AGREEMENT-NOT-FOUND (err u102))

(define-data-var agreement-counter uint u0)

(define-map sharing-agreements
  { agreement-id: uint }
  {
    data-owner: principal,
    recipient: principal,
    data-ref: uint,
    terms: (string-utf8 256),
    compensation: uint,
    created-at: uint,
    expires-at: uint,
    is-active: bool,
    access-count: uint
  }
)

(define-public (create-agreement
    (recipient principal)
    (data-ref uint)
    (terms (string-utf8 256))
    (compensation uint)
    (duration uint))
  (let
    ((new-id (+ (var-get agreement-counter) u1))
     (expiration (+ stacks-block-time duration)))
    (map-set sharing-agreements { agreement-id: new-id }
      {
        data-owner: tx-sender,
        recipient: recipient,
        data-ref: data-ref,
        terms: terms,
        compensation: compensation,
        created-at: stacks-block-time,
        expires-at: expiration,
        is-active: true,
        access-count: u0
      })
    (var-set agreement-counter new-id)
    (ok new-id)))

(define-public (terminate-agreement (agreement-id uint))
  (let
    ((agreement (unwrap! (map-get? sharing-agreements { agreement-id: agreement-id }) ERR-AGREEMENT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get data-owner agreement)) ERR-NOT-AUTHORIZED)
    (map-set sharing-agreements { agreement-id: agreement-id }
      (merge agreement { is-active: false }))
    (ok true)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-participant (participant principal))
  (principal-destruct? participant))

;; Clarity 4: int-to-ascii
(define-read-only (format-agreement-id (agreement-id uint))
  (ok (int-to-ascii agreement-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-agreement-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block)
  (ok burn-block-height))

(define-read-only (get-agreement (agreement-id uint))
  (ok (map-get? sharing-agreements { agreement-id: agreement-id })))

(define-read-only (is-agreement-active (agreement-id uint))
  (match (map-get? sharing-agreements { agreement-id: agreement-id })
    agreement (ok (and (get is-active agreement) (< stacks-block-time (get expires-at agreement))))
    (ok false)))
