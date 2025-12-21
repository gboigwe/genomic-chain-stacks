;; dicom-handler - Clarity 4
;; DICOM medical imaging handler and metadata registry

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-IMAGE-NOT-FOUND (err u101))
(define-constant ERR-INVALID-FORMAT (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))

(define-map dicom-images uint
  {
    patient-id: (string-ascii 50),
    study-id: (string-ascii 100),
    series-id: (string-ascii 100),
    image-hash: (buff 64),
    modality: (string-ascii 10),
    upload-timestamp: uint,
    uploader: principal,
    is-verified: bool
  }
)

(define-map study-metadata (string-ascii 100)
  {
    patient-id: (string-ascii 50),
    study-description: (string-utf8 200),
    study-date: uint,
    referring-physician: (string-utf8 100),
    number-of-series: uint,
    number-of-images: uint
  }
)

(define-map series-metadata (string-ascii 100)
  {
    study-id: (string-ascii 100),
    series-description: (string-utf8 200),
    modality: (string-ascii 10),
    body-part: (string-ascii 50),
    number-of-images: uint
  }
)

(define-map image-access-logs uint
  {
    image-id: uint,
    accessor: principal,
    access-timestamp: uint,
    access-reason: (string-utf8 200),
    access-granted: bool
  }
)

(define-data-var image-counter uint u0)
(define-data-var access-log-counter uint u0)

(define-public (register-dicom-image
    (patient-id (string-ascii 50))
    (study-id (string-ascii 100))
    (series-id (string-ascii 100))
    (image-hash (buff 64))
    (modality (string-ascii 10)))
  (let ((image-id (+ (var-get image-counter) u1)))
    (map-set dicom-images image-id
      {
        patient-id: patient-id,
        study-id: study-id,
        series-id: series-id,
        image-hash: image-hash,
        modality: modality,
        upload-timestamp: stacks-block-time,
        uploader: tx-sender,
        is-verified: false
      })
    (update-series-count series-id)
    (var-set image-counter image-id)
    (ok image-id)))

(define-public (register-study-metadata
    (study-id (string-ascii 100))
    (patient-id (string-ascii 50))
    (study-description (string-utf8 200))
    (study-date uint)
    (referring-physician (string-utf8 100)))
  (ok (map-set study-metadata study-id
    {
      patient-id: patient-id,
      study-description: study-description,
      study-date: study-date,
      referring-physician: referring-physician,
      number-of-series: u0,
      number-of-images: u0
    })))

(define-public (register-series-metadata
    (series-id (string-ascii 100))
    (study-id (string-ascii 100))
    (series-description (string-utf8 200))
    (modality (string-ascii 10))
    (body-part (string-ascii 50)))
  (ok (map-set series-metadata series-id
    {
      study-id: study-id,
      series-description: series-description,
      modality: modality,
      body-part: body-part,
      number-of-images: u0
    })))

(define-public (verify-image (image-id uint))
  (let ((image (unwrap! (map-get? dicom-images image-id) ERR-IMAGE-NOT-FOUND)))
    (ok (map-set dicom-images image-id
      (merge image { is-verified: true })))))

(define-public (log-image-access
    (image-id uint)
    (access-reason (string-utf8 200))
    (access-granted bool))
  (let ((log-id (+ (var-get access-log-counter) u1)))
    (map-set image-access-logs log-id
      {
        image-id: image-id,
        accessor: tx-sender,
        access-timestamp: stacks-block-time,
        access-reason: access-reason,
        access-granted: access-granted
      })
    (var-set access-log-counter log-id)
    (ok log-id)))

(define-private (update-series-count (series-id (string-ascii 100)))
  (let ((series (default-to
                  { study-id: "", series-description: u"", modality: "", body-part: "", number-of-images: u0 }
                  (map-get? series-metadata series-id))))
    (map-set series-metadata series-id
      (merge series { number-of-images: (+ (get number-of-images series) u1) }))
    true))

(define-read-only (get-dicom-image (image-id uint))
  (ok (map-get? dicom-images image-id)))

(define-read-only (get-study-metadata (study-id (string-ascii 100)))
  (ok (map-get? study-metadata study-id)))

(define-read-only (get-series-metadata (series-id (string-ascii 100)))
  (ok (map-get? series-metadata series-id)))

(define-read-only (get-access-log (log-id uint))
  (ok (map-get? image-access-logs log-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-image-id (image-id uint))
  (ok (int-to-ascii image-id)))

(define-read-only (parse-image-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
