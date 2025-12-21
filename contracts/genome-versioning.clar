;; genome-versioning - Clarity 4
;; Version control for genomic datasets

(define-constant ERR-VERSION-NOT-FOUND (err u100))
(define-data-var version-counter uint u0)

(define-map versions { version-id: uint }
  { data-id: uint, version-number: uint, data-hash: (buff 64), created-by: principal, created-at: uint, notes: (string-utf8 200) })

(define-public (create-version (data-id uint) (version-number uint) (data-hash (buff 64)) (notes (string-utf8 200)))
  (let ((new-id (+ (var-get version-counter) u1)))
    (map-set versions { version-id: new-id }
      { data-id: data-id, version-number: version-number, data-hash: data-hash, created-by: tx-sender, created-at: stacks-block-time, notes: notes })
    (var-set version-counter new-id)
    (ok new-id)))

(define-read-only (get-version (version-id uint))
  (ok (map-get? versions { version-id: version-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-creator (creator principal)) (principal-destruct? creator))

;; Clarity 4: int-to-utf8
(define-read-only (format-version-id (version-id uint)) (ok (int-to-utf8 version-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-version-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
