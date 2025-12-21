;; genome-access-control - Clarity 4
;; Fine-grained access control for genomic data

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PERMISSION-NOT-FOUND (err u101))

(define-map permissions { resource-id: uint, requester: principal }
  { granted-by: principal, access-level: (string-ascii 20), granted-at: uint, expires-at: uint })

(define-public (grant-permission (resource-id uint) (grantee principal) (access-level (string-ascii 20)) (expiration uint))
  (ok (map-set permissions { resource-id: resource-id, requester: grantee }
    { granted-by: tx-sender, access-level: access-level, granted-at: stacks-block-time, expires-at: expiration })))

(define-public (revoke-permission (resource-id uint) (grantee principal))
  (ok (map-delete permissions { resource-id: resource-id, requester: grantee })))

(define-read-only (check-permission (resource-id uint) (requester principal))
  (ok (map-get? permissions { resource-id: resource-id, requester: requester })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-requester (requester principal)) (principal-destruct? requester))

;; Clarity 4: int-to-ascii
(define-read-only (format-resource-id (resource-id uint)) (ok (int-to-ascii resource-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-resource-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
