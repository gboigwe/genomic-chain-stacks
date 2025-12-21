;; research-marketplace - Clarity 4
;; Marketplace for genomic data sharing with researchers

(define-constant ERR-LISTING-NOT-FOUND (err u100))
(define-data-var listing-counter uint u0)

(define-map data-listings { listing-id: uint }
  { provider: principal, data-type: (string-ascii 50), price: uint, sample-size: uint, created-at: uint, is-available: bool })

(define-public (create-listing (data-type (string-ascii 50)) (price uint) (sample-size uint))
  (let ((new-id (+ (var-get listing-counter) u1)))
    (map-set data-listings { listing-id: new-id }
      { provider: tx-sender, data-type: data-type, price: price, sample-size: sample-size, created-at: stacks-block-time, is-available: true })
    (var-set listing-counter new-id)
    (ok new-id)))

(define-read-only (get-listing (listing-id uint))
  (ok (map-get? data-listings { listing-id: listing-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-provider (provider principal)) (principal-destruct? provider))

;; Clarity 4: int-to-ascii
(define-read-only (format-listing-id (listing-id uint)) (ok (int-to-ascii listing-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-listing-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
