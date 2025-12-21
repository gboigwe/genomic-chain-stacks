;; lab-registry - Clarity 4
;; Laboratory registry and accreditation management

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-LAB-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-REGISTERED (err u102))

(define-map laboratories principal
  {
    lab-name: (string-utf8 200),
    license-number: (string-ascii 100),
    lab-type: (string-ascii 50),
    test-capabilities: (list 20 (string-ascii 50)),
    accreditation-status: (string-ascii 20),
    is-verified: bool,
    total-tests-performed: uint,
    registered-at: uint
  }
)

(define-map lab-accreditations uint
  {
    lab: principal,
    accrediting-body: (string-utf8 100),
    accreditation-type: (string-ascii 50),
    certificate-number: (string-ascii 100),
    issued-date: uint,
    expiry-date: uint,
    certificate-hash: (buff 64)
  }
)

(define-map test-results uint
  {
    lab: principal,
    patient-id: (string-ascii 50),
    test-type: (string-ascii 50),
    result-hash: (buff 64),
    performed-at: uint,
    technician: (optional principal),
    is-verified: bool
  }
)

(define-map quality-control-records uint
  {
    lab: principal,
    control-type: (string-ascii 50),
    test-date: uint,
    result-status: (string-ascii 20),
    performed-by: principal
  }
)

(define-data-var accreditation-counter uint u0)
(define-data-var test-counter uint u0)
(define-data-var qc-counter uint u0)

(define-public (register-lab
    (lab-name (string-utf8 200))
    (license-number (string-ascii 100))
    (lab-type (string-ascii 50))
    (test-capabilities (list 20 (string-ascii 50))))
  (begin
    (asserts! (is-none (map-get? laboratories tx-sender)) ERR-ALREADY-REGISTERED)
    (ok (map-set laboratories tx-sender
      {
        lab-name: lab-name,
        license-number: license-number,
        lab-type: lab-type,
        test-capabilities: test-capabilities,
        accreditation-status: "pending",
        is-verified: false,
        total-tests-performed: u0,
        registered-at: stacks-block-time
      }))))

(define-public (add-accreditation
    (accrediting-body (string-utf8 100))
    (accreditation-type (string-ascii 50))
    (certificate-number (string-ascii 100))
    (expiry-date uint)
    (certificate-hash (buff 64)))
  (let ((accred-id (+ (var-get accreditation-counter) u1)))
    (map-set lab-accreditations accred-id
      {
        lab: tx-sender,
        accrediting-body: accrediting-body,
        accreditation-type: accreditation-type,
        certificate-number: certificate-number,
        issued-date: stacks-block-time,
        expiry-date: expiry-date,
        certificate-hash: certificate-hash
      })
    (var-set accreditation-counter accred-id)
    (ok accred-id)))

(define-public (record-test-result
    (patient-id (string-ascii 50))
    (test-type (string-ascii 50))
    (result-hash (buff 64))
    (technician (optional principal)))
  (let ((test-id (+ (var-get test-counter) u1))
        (lab-data (unwrap! (map-get? laboratories tx-sender) ERR-LAB-NOT-FOUND)))
    (map-set test-results test-id
      {
        lab: tx-sender,
        patient-id: patient-id,
        test-type: test-type,
        result-hash: result-hash,
        performed-at: stacks-block-time,
        technician: technician,
        is-verified: false
      })
    (map-set laboratories tx-sender
      (merge lab-data { total-tests-performed: (+ (get total-tests-performed lab-data) u1) }))
    (var-set test-counter test-id)
    (ok test-id)))

(define-public (record-quality-control
    (control-type (string-ascii 50))
    (result-status (string-ascii 20)))
  (let ((qc-id (+ (var-get qc-counter) u1)))
    (map-set quality-control-records qc-id
      {
        lab: tx-sender,
        control-type: control-type,
        test-date: stacks-block-time,
        result-status: result-status,
        performed-by: tx-sender
      })
    (var-set qc-counter qc-id)
    (ok qc-id)))

(define-public (verify-test-result (test-id uint))
  (let ((test (unwrap! (map-get? test-results test-id) ERR-LAB-NOT-FOUND)))
    (ok (map-set test-results test-id
      (merge test { is-verified: true })))))

(define-read-only (get-lab (lab principal))
  (ok (map-get? laboratories lab)))

(define-read-only (get-accreditation (accreditation-id uint))
  (ok (map-get? lab-accreditations accreditation-id)))

(define-read-only (get-test-result (test-id uint))
  (ok (map-get? test-results test-id)))

(define-read-only (get-qc-record (qc-id uint))
  (ok (map-get? quality-control-records qc-id)))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-test-id (test-id uint))
  (ok (int-to-ascii test-id)))

(define-read-only (parse-test-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
