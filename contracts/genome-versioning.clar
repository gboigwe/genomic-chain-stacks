;; genome-versioning.clar - Clarity 4
;; Version control for genetic data

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-VERSION-NOT-FOUND (err u101))

(define-data-var version-counter uint u0)

(define-map dataset-versions
  { dataset-id: uint, version: uint }
  {
    creator: principal,
    data-hash: (buff 32),
    parent-version: (optional uint),
    created-at: uint,
    change-description: (string-utf8 256),
    is-current: bool
  }
)

(define-public (create-version
    (dataset-id uint)
    (data-hash (buff 32))
    (parent-version (optional uint))
    (description (string-utf8 256)))
  (let
    ((new-version (+ (var-get version-counter) u1)))
    (map-set dataset-versions { dataset-id: dataset-id, version: new-version }
      {
        creator: tx-sender,
        data-hash: data-hash,
        parent-version: parent-version,
        created-at: stacks-block-time,
        change-description: description,
        is-current: true
      })
    (var-set version-counter new-version)
    (ok new-version)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-creator (creator principal))
  (principal-destruct? creator))

;; Clarity 4: int-to-utf8
(define-read-only (format-version (version uint))
  (ok (int-to-utf8 version)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-version (version-str (string-ascii 20)))
  (string-to-uint? version-str))

(define-read-only (get-version (dataset-id uint) (version uint))
  (ok (map-get? dataset-versions { dataset-id: dataset-id, version: version })))
