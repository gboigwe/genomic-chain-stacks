;; faucet-genomic.clar - Clarity 4
;; Testnet faucet for genomic tokens

(define-constant ERR-ALREADY-CLAIMED (err u400))
(define-constant DRIP-AMOUNT u1000000)

(define-data-var total-distributed uint u0)

(define-map claims
  { claimer: principal }
  { amount: uint, claimed-at: uint }
)

(define-public (claim-tokens)
  (let
    ((caller tx-sender))
    (asserts! (is-none (map-get? claims { claimer: caller })) ERR-ALREADY-CLAIMED)
    (map-set claims { claimer: caller }
      { amount: DRIP-AMOUNT, claimed-at: stacks-block-time })
    (var-set total-distributed (+ (var-get total-distributed) DRIP-AMOUNT))
    (ok DRIP-AMOUNT)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-claimer (claimer principal))
  (principal-destruct? claimer))

;; Clarity 4: int-to-utf8
(define-read-only (format-total-distributed)
  (ok (int-to-utf8 (var-get total-distributed))))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-height)
  (ok burn-block-height))

(define-read-only (get-claim (claimer principal))
  (ok (map-get? claims { claimer: claimer })))

(define-read-only (get-total-distributed)
  (ok (var-get total-distributed)))
