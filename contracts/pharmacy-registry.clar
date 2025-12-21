;; pharmacy-registry - Clarity 4
;; Comprehensive pharmacy and medication dispensing registry

(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-LICENSE (err u103))

(define-map pharmacies principal
  {
    pharmacy-name: (string-utf8 200),
    license-number: (string-ascii 100),
    address: (string-utf8 300),
    contact-info: (string-utf8 100),
    license-expiry: uint,
    is-active: bool,
    registered-at: uint
  }
)

(define-map dispensing-records uint
  {
    pharmacy: principal,
    patient: principal,
    prescription-id: uint,
    medication-name: (string-utf8 100),
    quantity: uint,
    dispensed-at: uint,
    pharmacist: principal
  }
)

(define-map medication-inventory { pharmacy: principal, medication-id: uint }
  {
    medication-name: (string-utf8 100),
    stock-quantity: uint,
    reorder-level: uint,
    last-restocked: uint,
    expiry-date: uint
  }
)

(define-map pharmacy-certifications { pharmacy: principal, cert-type: (string-ascii 50) }
  {
    certification-name: (string-utf8 100),
    issued-by: (string-utf8 100),
    issued-at: uint,
    expires-at: uint,
    is-valid: bool
  }
)

(define-data-var dispensing-counter uint u0)
(define-data-var medication-id-counter uint u0)

(define-public (register-pharmacy
    (pharmacy-name (string-utf8 200))
    (license-number (string-ascii 100))
    (address (string-utf8 300))
    (contact-info (string-utf8 100))
    (license-expiry uint))
  (begin
    (asserts! (is-none (map-get? pharmacies tx-sender)) ERR-ALREADY-EXISTS)
    (ok (map-set pharmacies tx-sender
      {
        pharmacy-name: pharmacy-name,
        license-number: license-number,
        address: address,
        contact-info: contact-info,
        license-expiry: license-expiry,
        is-active: true,
        registered-at: stacks-block-time
      }))))

(define-public (record-dispensing
    (patient principal)
    (prescription-id uint)
    (medication-name (string-utf8 100))
    (quantity uint)
    (pharmacist principal))
  (let ((dispensing-id (+ (var-get dispensing-counter) u1))
        (pharmacy (unwrap! (map-get? pharmacies tx-sender) ERR-NOT-FOUND)))
    (asserts! (get is-active pharmacy) ERR-NOT-AUTHORIZED)
    (map-set dispensing-records dispensing-id
      {
        pharmacy: tx-sender,
        patient: patient,
        prescription-id: prescription-id,
        medication-name: medication-name,
        quantity: quantity,
        dispensed-at: stacks-block-time,
        pharmacist: pharmacist
      })
    (var-set dispensing-counter dispensing-id)
    (ok dispensing-id)))

(define-public (update-inventory
    (medication-id uint)
    (medication-name (string-utf8 100))
    (stock-quantity uint)
    (reorder-level uint)
    (expiry-date uint))
  (let ((pharmacy (unwrap! (map-get? pharmacies tx-sender) ERR-NOT-FOUND)))
    (asserts! (get is-active pharmacy) ERR-NOT-AUTHORIZED)
    (ok (map-set medication-inventory { pharmacy: tx-sender, medication-id: medication-id }
      {
        medication-name: medication-name,
        stock-quantity: stock-quantity,
        reorder-level: reorder-level,
        last-restocked: stacks-block-time,
        expiry-date: expiry-date
      }))))

(define-public (add-certification
    (cert-type (string-ascii 50))
    (certification-name (string-utf8 100))
    (issued-by (string-utf8 100))
    (duration uint))
  (let ((pharmacy (unwrap! (map-get? pharmacies tx-sender) ERR-NOT-FOUND)))
    (ok (map-set pharmacy-certifications { pharmacy: tx-sender, cert-type: cert-type }
      {
        certification-name: certification-name,
        issued-by: issued-by,
        issued-at: stacks-block-time,
        expires-at: (+ stacks-block-time duration),
        is-valid: true
      }))))

(define-public (deactivate-pharmacy)
  (let ((pharmacy (unwrap! (map-get? pharmacies tx-sender) ERR-NOT-FOUND)))
    (ok (map-set pharmacies tx-sender
      (merge pharmacy { is-active: false })))))

(define-read-only (get-pharmacy (pharmacy principal))
  (ok (map-get? pharmacies pharmacy)))

(define-read-only (get-dispensing-record (dispensing-id uint))
  (ok (map-get? dispensing-records dispensing-id)))

(define-read-only (get-inventory (pharmacy principal) (medication-id uint))
  (ok (map-get? medication-inventory { pharmacy: pharmacy, medication-id: medication-id })))

(define-read-only (get-certification (pharmacy principal) (cert-type (string-ascii 50)))
  (ok (map-get? pharmacy-certifications { pharmacy: pharmacy, cert-type: cert-type })))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-dispensing-id (dispensing-id uint))
  (ok (int-to-ascii dispensing-id)))

(define-read-only (parse-dispensing-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
