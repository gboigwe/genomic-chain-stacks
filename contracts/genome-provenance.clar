;; genome-provenance - Clarity 4
;; Track chain of custody for genomic data

(define-constant ERR-EVENT-NOT-FOUND (err u100))
(define-data-var event-counter uint u0)

(define-map provenance-events { event-id: uint }
  { data-id: uint, actor: principal, action: (string-ascii 50), timestamp: uint, location: (string-ascii 100) })

(define-public (log-event (data-id uint) (action (string-ascii 50)) (location (string-ascii 100)))
  (let ((new-id (+ (var-get event-counter) u1)))
    (map-set provenance-events { event-id: new-id }
      { data-id: data-id, actor: tx-sender, action: action, timestamp: stacks-block-time, location: location })
    (var-set event-counter new-id)
    (ok new-id)))

(define-read-only (get-event (event-id uint))
  (ok (map-get? provenance-events { event-id: event-id })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-actor (actor principal)) (principal-destruct? actor))

;; Clarity 4: int-to-utf8
(define-read-only (format-event-id (event-id uint)) (ok (int-to-utf8 event-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-event-id (id-str (string-ascii 20))) (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block) (ok burn-block-height))
