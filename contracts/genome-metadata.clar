;; genome-metadata - Clarity 4
;; Metadata storage for genomic datasets

(define-constant ERR-NOT-FOUND (err u100))

(define-map metadata { data-id: uint }
  { owner: principal, sample-type: (string-ascii 50), sequencing-method: (string-ascii 50), quality-score: uint, created-at: uint })

(define-public (store-metadata (data-id uint) (sample-type (string-ascii 50)) (sequencing-method (string-ascii 50)) (quality-score uint))
  (ok (map-set metadata { data-id: data-id }
    { owner: tx-sender, sample-type: sample-type, sequencing-method: sequencing-method, quality-score: quality-score, created-at: stacks-block-time })))

(define-read-only (get-metadata (data-id uint))
  (ok (map-get? metadata { data-id: data-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-owner (owner principal)) (principal-destruct? owner))

;; Clarity 4: int-to-ascii
(define-read-only (format-data-id (data-id uint)) (ok (int-to-ascii data-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-data-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
