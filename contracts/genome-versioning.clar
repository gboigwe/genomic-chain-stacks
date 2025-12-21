;; genome-versioning - Clarity 4
;; Version control for genomic datasets

(define-constant ERR-VERSION-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-VERSION (err u102))
(define-constant ERR-VERSION-CONFLICT (err u103))

(define-map versions uint
  {
    data-id: uint,
    version-number: uint,
    data-hash: (buff 64),
    created-by: principal,
    created-at: uint,
    notes: (string-utf8 200),
    parent-version: (optional uint),
    is-stable: bool,
    changelog: (string-utf8 500)
  }
)

(define-map version-metadata uint
  {
    version-id: uint,
    file-size: uint,
    compression-type: (string-ascii 20),
    checksum: (buff 32),
    format-version: (string-ascii 20),
    schema-version: uint
  }
)

(define-map version-tags { version-id: uint, tag-name: (string-ascii 50) }
  {
    tag-type: (string-ascii 20),
    created-at: uint,
    created-by: principal,
    description: (string-utf8 200)
  }
)

(define-map version-branches uint
  {
    data-id: uint,
    branch-name: (string-ascii 50),
    base-version: uint,
    head-version: uint,
    created-by: principal,
    created-at: uint,
    is-merged: bool
  }
)

(define-map version-diffs uint
  {
    from-version: uint,
    to-version: uint,
    diff-hash: (buff 64),
    changes-count: uint,
    computed-at: uint,
    computed-by: principal
  }
)

(define-map merge-operations uint
  {
    source-version: uint,
    target-version: uint,
    merged-version: uint,
    merge-strategy: (string-ascii 50),
    conflicts-count: uint,
    merged-by: principal,
    merged-at: uint
  }
)

(define-data-var version-counter uint u0)
(define-data-var metadata-counter uint u0)
(define-data-var branch-counter uint u0)
(define-data-var diff-counter uint u0)
(define-data-var merge-counter uint u0)

(define-public (create-version
    (data-id uint)
    (version-number uint)
    (data-hash (buff 64))
    (notes (string-utf8 200))
    (parent-version (optional uint))
    (changelog (string-utf8 500)))
  (let ((version-id (+ (var-get version-counter) u1)))
    (map-set versions version-id
      {
        data-id: data-id,
        version-number: version-number,
        data-hash: data-hash,
        created-by: tx-sender,
        created-at: stacks-block-time,
        notes: notes,
        parent-version: parent-version,
        is-stable: false,
        changelog: changelog
      })
    (var-set version-counter version-id)
    (ok version-id)))

(define-public (add-version-metadata
    (version-id uint)
    (file-size uint)
    (compression-type (string-ascii 20))
    (checksum (buff 32))
    (format-version (string-ascii 20))
    (schema-version uint))
  (let ((metadata-id (+ (var-get metadata-counter) u1)))
    (asserts! (is-some (map-get? versions version-id)) ERR-VERSION-NOT-FOUND)
    (map-set version-metadata metadata-id
      {
        version-id: version-id,
        file-size: file-size,
        compression-type: compression-type,
        checksum: checksum,
        format-version: format-version,
        schema-version: schema-version
      })
    (var-set metadata-counter metadata-id)
    (ok metadata-id)))

(define-public (tag-version
    (version-id uint)
    (tag-name (string-ascii 50))
    (tag-type (string-ascii 20))
    (description (string-utf8 200)))
  (begin
    (asserts! (is-some (map-get? versions version-id)) ERR-VERSION-NOT-FOUND)
    (map-set version-tags { version-id: version-id, tag-name: tag-name }
      {
        tag-type: tag-type,
        created-at: stacks-block-time,
        created-by: tx-sender,
        description: description
      })
    (ok true)))

(define-public (create-branch
    (data-id uint)
    (branch-name (string-ascii 50))
    (base-version uint))
  (let ((branch-id (+ (var-get branch-counter) u1)))
    (asserts! (is-some (map-get? versions base-version)) ERR-VERSION-NOT-FOUND)
    (map-set version-branches branch-id
      {
        data-id: data-id,
        branch-name: branch-name,
        base-version: base-version,
        head-version: base-version,
        created-by: tx-sender,
        created-at: stacks-block-time,
        is-merged: false
      })
    (var-set branch-counter branch-id)
    (ok branch-id)))

(define-public (compute-diff
    (from-version uint)
    (to-version uint)
    (diff-hash (buff 64))
    (changes-count uint))
  (let ((diff-id (+ (var-get diff-counter) u1)))
    (asserts! (is-some (map-get? versions from-version)) ERR-VERSION-NOT-FOUND)
    (asserts! (is-some (map-get? versions to-version)) ERR-VERSION-NOT-FOUND)
    (map-set version-diffs diff-id
      {
        from-version: from-version,
        to-version: to-version,
        diff-hash: diff-hash,
        changes-count: changes-count,
        computed-at: stacks-block-time,
        computed-by: tx-sender
      })
    (var-set diff-counter diff-id)
    (ok diff-id)))

(define-public (merge-versions
    (source-version uint)
    (target-version uint)
    (merged-version uint)
    (merge-strategy (string-ascii 50))
    (conflicts-count uint))
  (let ((merge-id (+ (var-get merge-counter) u1)))
    (map-set merge-operations merge-id
      {
        source-version: source-version,
        target-version: target-version,
        merged-version: merged-version,
        merge-strategy: merge-strategy,
        conflicts-count: conflicts-count,
        merged-by: tx-sender,
        merged-at: stacks-block-time
      })
    (var-set merge-counter merge-id)
    (ok merge-id)))

(define-public (mark-stable (version-id uint))
  (let ((version (unwrap! (map-get? versions version-id) ERR-VERSION-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get created-by version)) ERR-NOT-AUTHORIZED)
    (ok (map-set versions version-id
      (merge version { is-stable: true })))))

(define-read-only (get-version (version-id uint))
  (ok (map-get? versions version-id)))

(define-read-only (get-version-metadata (metadata-id uint))
  (ok (map-get? version-metadata metadata-id)))

(define-read-only (get-version-tag (version-id uint) (tag-name (string-ascii 50)))
  (ok (map-get? version-tags { version-id: version-id, tag-name: tag-name })))

(define-read-only (get-branch (branch-id uint))
  (ok (map-get? version-branches branch-id)))

(define-read-only (get-diff (diff-id uint))
  (ok (map-get? version-diffs diff-id)))

(define-read-only (get-merge (merge-id uint))
  (ok (map-get? merge-operations merge-id)))

(define-read-only (validate-creator (creator principal))
  (principal-destruct? creator))

(define-read-only (format-version-id (version-id uint))
  (ok (int-to-ascii version-id)))

(define-read-only (parse-version-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
