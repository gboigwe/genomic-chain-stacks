;; hospital-registry - Clarity 4
;; Hospital and healthcare facility registry and verification

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-HOSPITAL-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-REGISTERED (err u102))
(define-constant ERR-NOT-VERIFIED (err u103))

(define-map hospitals principal
  {
    hospital-name: (string-utf8 200),
    license-number: (string-ascii 100),
    facility-type: (string-ascii 50),
    address: (string-utf8 300),
    contact-info: (string-utf8 200),
    accreditation: (string-ascii 50),
    is-verified: bool,
    verification-date: (optional uint),
    total-patients: uint
  }
)

(define-map hospital-departments { hospital: principal, department-id: uint }
  {
    department-name: (string-utf8 100),
    department-head: (string-utf8 100),
    specialization: (string-ascii 50),
    bed-capacity: uint,
    is-active: bool
  }
)

(define-map hospital-staff { hospital: principal, staff-id: principal }
  {
    staff-name: (string-utf8 100),
    role: (string-ascii 50),
    department: uint,
    license-number: (string-ascii 100),
    joined-date: uint,
    is-active: bool
  }
)

(define-map hospital-accreditations uint
  {
    hospital: principal,
    accreditation-body: (string-utf8 100),
    accreditation-type: (string-ascii 50),
    issued-date: uint,
    expiry-date: uint,
    certificate-hash: (buff 64)
  }
)

(define-map patient-admissions uint
  {
    hospital: principal,
    patient-id: (string-ascii 50),
    admission-date: uint,
    discharge-date: (optional uint),
    department: uint,
    status: (string-ascii 20)
  }
)

(define-data-var department-counter uint u0)
(define-data-var accreditation-counter uint u0)
(define-data-var admission-counter uint u0)

(define-public (register-hospital
    (hospital-name (string-utf8 200))
    (license-number (string-ascii 100))
    (facility-type (string-ascii 50))
    (address (string-utf8 300))
    (contact-info (string-utf8 200))
    (accreditation (string-ascii 50)))
  (begin
    (asserts! (is-none (map-get? hospitals tx-sender)) ERR-ALREADY-REGISTERED)
    (ok (map-set hospitals tx-sender
      {
        hospital-name: hospital-name,
        license-number: license-number,
        facility-type: facility-type,
        address: address,
        contact-info: contact-info,
        accreditation: accreditation,
        is-verified: false,
        verification-date: none,
        total-patients: u0
      }))))

(define-public (verify-hospital (hospital principal))
  (let ((hospital-data (unwrap! (map-get? hospitals hospital) ERR-HOSPITAL-NOT-FOUND)))
    (ok (map-set hospitals hospital
      (merge hospital-data {
        is-verified: true,
        verification-date: (some stacks-block-time)
      })))))

(define-public (add-department
    (department-name (string-utf8 100))
    (department-head (string-utf8 100))
    (specialization (string-ascii 50))
    (bed-capacity uint))
  (let ((department-id (+ (var-get department-counter) u1))
        (hospital-data (unwrap! (map-get? hospitals tx-sender) ERR-HOSPITAL-NOT-FOUND)))
    (asserts! (get is-verified hospital-data) ERR-NOT-VERIFIED)
    (map-set hospital-departments { hospital: tx-sender, department-id: department-id }
      {
        department-name: department-name,
        department-head: department-head,
        specialization: specialization,
        bed-capacity: bed-capacity,
        is-active: true
      })
    (var-set department-counter department-id)
    (ok department-id)))

(define-public (register-staff
    (staff-id principal)
    (staff-name (string-utf8 100))
    (role (string-ascii 50))
    (department uint)
    (license-number (string-ascii 100)))
  (let ((hospital-data (unwrap! (map-get? hospitals tx-sender) ERR-HOSPITAL-NOT-FOUND)))
    (asserts! (get is-verified hospital-data) ERR-NOT-VERIFIED)
    (ok (map-set hospital-staff { hospital: tx-sender, staff-id: staff-id }
      {
        staff-name: staff-name,
        role: role,
        department: department,
        license-number: license-number,
        joined-date: stacks-block-time,
        is-active: true
      }))))

(define-public (add-accreditation
    (accreditation-body (string-utf8 100))
    (accreditation-type (string-ascii 50))
    (expiry-date uint)
    (certificate-hash (buff 64)))
  (let ((accreditation-id (+ (var-get accreditation-counter) u1))
        (hospital-data (unwrap! (map-get? hospitals tx-sender) ERR-HOSPITAL-NOT-FOUND)))
    (map-set hospital-accreditations accreditation-id
      {
        hospital: tx-sender,
        accreditation-body: accreditation-body,
        accreditation-type: accreditation-type,
        issued-date: stacks-block-time,
        expiry-date: expiry-date,
        certificate-hash: certificate-hash
      })
    (var-set accreditation-counter accreditation-id)
    (ok accreditation-id)))

(define-public (record-admission
    (patient-id (string-ascii 50))
    (department uint))
  (let ((admission-id (+ (var-get admission-counter) u1))
        (hospital-data (unwrap! (map-get? hospitals tx-sender) ERR-HOSPITAL-NOT-FOUND)))
    (map-set patient-admissions admission-id
      {
        hospital: tx-sender,
        patient-id: patient-id,
        admission-date: stacks-block-time,
        discharge-date: none,
        department: department,
        status: "active"
      })
    (map-set hospitals tx-sender
      (merge hospital-data { total-patients: (+ (get total-patients hospital-data) u1) }))
    (var-set admission-counter admission-id)
    (ok admission-id)))

(define-read-only (get-hospital (hospital principal))
  (ok (map-get? hospitals hospital)))

(define-read-only (get-department (hospital principal) (department-id uint))
  (ok (map-get? hospital-departments { hospital: hospital, department-id: department-id })))

(define-read-only (get-staff (hospital principal) (staff-id principal))
  (ok (map-get? hospital-staff { hospital: hospital, staff-id: staff-id })))

(define-read-only (get-accreditation (accreditation-id uint))
  (ok (map-get? hospital-accreditations accreditation-id)))

(define-read-only (get-admission (admission-id uint))
  (ok (map-get? patient-admissions admission-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-admission-id (admission-id uint))
  (ok (int-to-ascii admission-id)))

(define-read-only (parse-admission-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
