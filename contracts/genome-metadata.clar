;; genome-metadata.clar - Clarity 4
;; Metadata management for genomic datasets

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-METADATA-NOT-FOUND (err u101))

(define-map dataset-metadata
  { dataset-id: uint }
  {
    owner: principal,
    title: (string-utf8 100),
    description: (string-utf8 500),
    sample-type: (string-ascii 50),
    sequencing-platform: (string-ascii 50),
    read-depth: uint,
    genome-build: (string-ascii 20),
    created-at: uint,
    file-size: uint,
    checksum: (buff 32)
  }
)

(define-public (set-metadata
    (dataset-id uint)
    (title (string-utf8 100))
    (description (string-utf8 500))
    (sample-type (string-ascii 50))
    (platform (string-ascii 50))
    (read-depth uint)
    (genome-build (string-ascii 20))
    (file-size uint)
    (checksum (buff 32)))
  (begin
    (map-set dataset-metadata { dataset-id: dataset-id }
      {
        owner: tx-sender,
        title: title,
        description: description,
        sample-type: sample-type,
        sequencing-platform: platform,
        read-depth: read-depth,
        genome-build: genome-build,
        created-at: stacks-block-time,
        file-size: file-size,
        checksum: checksum
      })
    (ok true)))

;; Clarity 4: principal-destruct?
(define-read-only (validate-owner (owner principal))
  (principal-destruct? owner))

;; Clarity 4: int-to-utf8
(define-read-only (format-dataset-id (dataset-id uint))
  (ok (int-to-utf8 dataset-id)))

;; Clarity 4: buff-to-uint-le
(define-read-only (checksum-to-number (checksum-buff (buff 16)))
  (ok (buff-to-uint-le checksum-buff)))

(define-read-only (get-metadata (dataset-id uint))
  (ok (map-get? dataset-metadata { dataset-id: dataset-id })))
