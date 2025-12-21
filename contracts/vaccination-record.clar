;; vaccination-record - Clarity 4
;; Vaccination history and verification

(define-constant ERR-RECORD-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-VACCINE (err u102))

(define-map vaccination-records uint
  {
    patient: principal,
    provider: principal,
    vaccine-name: (string-ascii 100),
    administered-at: uint,
    lot-number: (string-ascii 50),
    dose-number: uint,
    next-dose: (optional uint),
    site: (string-ascii 50),
    route: (string-ascii 20),
    is-verified: bool
  }
)

(define-map vaccine-types uint
  {
    vaccine-name: (string-utf8 100),
    manufacturer: (string-utf8 100),
    disease-target: (string-utf8 100),
    dose-schedule: (list 5 uint),
    age-restrictions: (string-utf8 200),
    is-approved: bool
  }
)

(define-map adverse-reactions uint
  {
    vaccination-id: uint,
    patient: principal,
    reaction-type: (string-ascii 50),
    severity: (string-ascii 20),
    onset-time: uint,
    duration: (optional uint),
    reported-by: principal,
    reported-at: uint
  }
)

(define-map immunity-certificates uint
  {
    patient: principal,
    disease: (string-utf8 100),
    vaccination-ids: (list 10 uint),
    issue-date: uint,
    expiry-date: (optional uint),
    issued-by: principal,
    certificate-id: (string-ascii 100)
  }
)

(define-map vaccine-inventory uint
  {
    provider: principal,
    vaccine-name: (string-ascii 100),
    lot-number: (string-ascii 50),
    quantity: uint,
    expiry-date: uint,
    storage-temp: int,
    is-available: bool
  }
)

(define-data-var record-counter uint u0)
(define-data-var vaccine-type-counter uint u0)
(define-data-var reaction-counter uint u0)
(define-data-var certificate-counter uint u0)
(define-data-var inventory-counter uint u0)

(define-public (record-vaccination
    (patient principal)
    (vaccine-name (string-ascii 100))
    (lot-number (string-ascii 50))
    (dose-number uint)
    (next-dose (optional uint))
    (site (string-ascii 50))
    (route (string-ascii 20)))
  (let ((record-id (+ (var-get record-counter) u1)))
    (map-set vaccination-records record-id
      {
        patient: patient,
        provider: tx-sender,
        vaccine-name: vaccine-name,
        administered-at: stacks-block-time,
        lot-number: lot-number,
        dose-number: dose-number,
        next-dose: next-dose,
        site: site,
        route: route,
        is-verified: false
      })
    (var-set record-counter record-id)
    (ok record-id)))

(define-public (verify-vaccination (record-id uint))
  (let ((record (unwrap! (map-get? vaccination-records record-id) ERR-RECORD-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get provider record)) ERR-NOT-AUTHORIZED)
    (ok (map-set vaccination-records record-id
      (merge record { is-verified: true })))))

(define-public (register-vaccine-type
    (vaccine-name (string-utf8 100))
    (manufacturer (string-utf8 100))
    (disease-target (string-utf8 100))
    (dose-schedule (list 5 uint))
    (age-restrictions (string-utf8 200)))
  (let ((vaccine-id (+ (var-get vaccine-type-counter) u1)))
    (map-set vaccine-types vaccine-id
      {
        vaccine-name: vaccine-name,
        manufacturer: manufacturer,
        disease-target: disease-target,
        dose-schedule: dose-schedule,
        age-restrictions: age-restrictions,
        is-approved: false
      })
    (var-set vaccine-type-counter vaccine-id)
    (ok vaccine-id)))

(define-public (report-adverse-reaction
    (vaccination-id uint)
    (reaction-type (string-ascii 50))
    (severity (string-ascii 20))
    (onset-time uint)
    (duration (optional uint)))
  (let ((reaction-id (+ (var-get reaction-counter) u1))
        (record (unwrap! (map-get? vaccination-records vaccination-id) ERR-RECORD-NOT-FOUND)))
    (map-set adverse-reactions reaction-id
      {
        vaccination-id: vaccination-id,
        patient: (get patient record),
        reaction-type: reaction-type,
        severity: severity,
        onset-time: onset-time,
        duration: duration,
        reported-by: tx-sender,
        reported-at: stacks-block-time
      })
    (var-set reaction-counter reaction-id)
    (ok reaction-id)))

(define-public (issue-immunity-certificate
    (patient principal)
    (disease (string-utf8 100))
    (vaccination-ids (list 10 uint))
    (expiry-date (optional uint))
    (certificate-id (string-ascii 100)))
  (let ((cert-id (+ (var-get certificate-counter) u1)))
    (map-set immunity-certificates cert-id
      {
        patient: patient,
        disease: disease,
        vaccination-ids: vaccination-ids,
        issue-date: stacks-block-time,
        expiry-date: expiry-date,
        issued-by: tx-sender,
        certificate-id: certificate-id
      })
    (var-set certificate-counter cert-id)
    (ok cert-id)))

(define-read-only (get-record (record-id uint))
  (ok (map-get? vaccination-records record-id)))

(define-read-only (get-vaccine-type (vaccine-id uint))
  (ok (map-get? vaccine-types vaccine-id)))

(define-read-only (get-adverse-reaction (reaction-id uint))
  (ok (map-get? adverse-reactions reaction-id)))

(define-read-only (get-immunity-certificate (cert-id uint))
  (ok (map-get? immunity-certificates cert-id)))

(define-read-only (validate-provider (provider principal))
  (principal-destruct? provider))

(define-read-only (format-record-id (record-id uint))
  (ok (int-to-ascii record-id)))

(define-read-only (parse-record-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
