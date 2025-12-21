;; genome-sharing - Clarity 4
;; Secure sharing of genomic data between parties

(define-constant ERR-SHARE-NOT-FOUND (err u100))
(define-data-var share-counter uint u0)

(define-map shares { share-id: uint }
  { owner: principal, recipient: principal, data-ref: uint, shared-at: uint, expires-at: uint, is-active: bool })

(define-public (create-share (recipient principal) (data-ref uint) (expiration uint))
  (let ((new-id (+ (var-get share-counter) u1)))
    (map-set shares { share-id: new-id }
      { owner: tx-sender, recipient: recipient, data-ref: data-ref, shared-at: stacks-block-time, expires-at: expiration, is-active: true })
    (var-set share-counter new-id)
    (ok new-id)))

(define-public (revoke-share (share-id uint))
  (let ((share (unwrap! (map-get? shares { share-id: share-id }) ERR-SHARE-NOT-FOUND)))
    (ok (map-set shares { share-id: share-id } (merge share { is-active: false })))))

(define-read-only (get-share (share-id uint))
  (ok (map-get? shares { share-id: share-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-recipient (recipient principal)) (principal-destruct? recipient))

;; Clarity 4: int-to-utf8
(define-read-only (format-share-id (share-id uint)) (ok (int-to-utf8 share-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-share-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
