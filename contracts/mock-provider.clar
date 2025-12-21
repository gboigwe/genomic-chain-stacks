;; mock-provider - Clarity 4
;; Mock healthcare provider generator for testing and development

(define-constant ERR-INVALID-INDEX (err u100))

(define-data-var provider-counter uint u0)

(define-map mock-providers uint
  {
    provider-id: (string-ascii 50),
    provider-name: (string-utf8 200),
    provider-type: (string-ascii 50),
    license-number: (string-ascii 100),
    specialization: (string-ascii 50),
    location: (string-utf8 200),
    contact: (string-utf8 100),
    created-at: uint
  }
)

(define-map mock-services uint
  {
    provider-id: uint,
    service-name: (string-utf8 100),
    service-code: (string-ascii 20),
    base-price: uint,
    duration-minutes: uint
  }
)

(define-map mock-appointments uint
  {
    provider-id: uint,
    patient-id: (string-ascii 50),
    appointment-date: uint,
    service-code: (string-ascii 20),
    status: (string-ascii 20)
  }
)

(define-public (generate-mock-provider
    (provider-id (string-ascii 50))
    (name (string-utf8 200))
    (provider-type (string-ascii 50))
    (license (string-ascii 100))
    (specialization (string-ascii 50))
    (location (string-utf8 200))
    (contact (string-utf8 100)))
  (let ((id (+ (var-get provider-counter) u1)))
    (map-set mock-providers id
      {
        provider-id: provider-id,
        provider-name: name,
        provider-type: provider-type,
        license-number: license,
        specialization: specialization,
        location: location,
        contact: contact,
        created-at: stacks-block-time
      })
    (var-set provider-counter id)
    (ok id)))

(define-public (generate-mock-service
    (provider-id uint)
    (service-name (string-utf8 100))
    (service-code (string-ascii 20))
    (price uint)
    (duration uint))
  (let ((service-id (+ (var-get provider-counter) u1)))
    (map-set mock-services service-id
      {
        provider-id: provider-id,
        service-name: service-name,
        service-code: service-code,
        base-price: price,
        duration-minutes: duration
      })
    (var-set provider-counter service-id)
    (ok service-id)))

(define-public (generate-mock-appointment
    (provider-id uint)
    (patient-id (string-ascii 50))
    (appointment-date uint)
    (service-code (string-ascii 20))
    (status (string-ascii 20)))
  (let ((appointment-id (+ (var-get provider-counter) u1)))
    (map-set mock-appointments appointment-id
      {
        provider-id: provider-id,
        patient-id: patient-id,
        appointment-date: appointment-date,
        service-code: service-code,
        status: status
      })
    (var-set provider-counter appointment-id)
    (ok appointment-id)))

(define-read-only (get-mock-provider (id uint))
  (ok (map-get? mock-providers id)))

(define-read-only (get-mock-service (service-id uint))
  (ok (map-get? mock-services service-id)))

(define-read-only (get-mock-appointment (appointment-id uint))
  (ok (map-get? mock-appointments appointment-id)))

(define-read-only (get-provider-count)
  (ok (var-get provider-counter)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-id (id uint))
  (ok (int-to-ascii id)))

(define-read-only (parse-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
