;; time-utils-health - Clarity 4
;; Time and scheduling utility functions for healthcare operations

(define-constant ERR-INVALID-TIME (err u100))
(define-constant ERR-PAST-TIME (err u101))

(define-constant SECONDS-PER-DAY u86400)
(define-constant SECONDS-PER-HOUR u3600)
(define-constant SECONDS-PER-MINUTE u60)

(define-map scheduled-events uint
  {
    event-name: (string-utf8 100),
    event-type: (string-ascii 50),
    scheduled-time: uint,
    duration: uint,
    organizer: principal,
    is-recurring: bool,
    recurrence-interval: uint
  }
)

(define-map time-windows uint
  {
    window-name: (string-utf8 100),
    start-time: uint,
    end-time: uint,
    time-zone: (string-ascii 50),
    is-active: bool
  }
)

(define-map appointment-slots { date: uint, slot-id: uint }
  {
    start-time: uint,
    end-time: uint,
    is-available: bool,
    booked-by: (optional principal)
  }
)

(define-map recurring-schedules uint
  {
    schedule-name: (string-utf8 100),
    base-time: uint,
    interval-type: (string-ascii 20),
    interval-value: uint,
    end-date: (optional uint)
  }
)

(define-data-var event-counter uint u0)
(define-data-var window-counter uint u0)
(define-data-var schedule-counter uint u0)

(define-public (schedule-event
    (event-name (string-utf8 100))
    (event-type (string-ascii 50))
    (scheduled-time uint)
    (duration uint)
    (is-recurring bool)
    (recurrence-interval uint))
  (let ((event-id (+ (var-get event-counter) u1)))
    (asserts! (> scheduled-time stacks-block-time) ERR-PAST-TIME)
    (map-set scheduled-events event-id
      {
        event-name: event-name,
        event-type: event-type,
        scheduled-time: scheduled-time,
        duration: duration,
        organizer: tx-sender,
        is-recurring: is-recurring,
        recurrence-interval: recurrence-interval
      })
    (var-set event-counter event-id)
    (ok event-id)))

(define-public (create-time-window
    (window-name (string-utf8 100))
    (start-time uint)
    (end-time uint)
    (time-zone (string-ascii 50)))
  (let ((window-id (+ (var-get window-counter) u1)))
    (asserts! (< start-time end-time) ERR-INVALID-TIME)
    (map-set time-windows window-id
      {
        window-name: window-name,
        start-time: start-time,
        end-time: end-time,
        time-zone: time-zone,
        is-active: true
      })
    (var-set window-counter window-id)
    (ok window-id)))

(define-public (book-appointment-slot
    (date uint)
    (slot-id uint))
  (let ((slot (unwrap! (map-get? appointment-slots { date: date, slot-id: slot-id }) ERR-INVALID-TIME)))
    (asserts! (get is-available slot) ERR-INVALID-TIME)
    (ok (map-set appointment-slots { date: date, slot-id: slot-id }
      (merge slot {
        is-available: false,
        booked-by: (some tx-sender)
      })))))

(define-public (create-recurring-schedule
    (schedule-name (string-utf8 100))
    (base-time uint)
    (interval-type (string-ascii 20))
    (interval-value uint)
    (end-date (optional uint)))
  (let ((schedule-id (+ (var-get schedule-counter) u1)))
    (map-set recurring-schedules schedule-id
      {
        schedule-name: schedule-name,
        base-time: base-time,
        interval-type: interval-type,
        interval-value: interval-value,
        end-date: end-date
      })
    (var-set schedule-counter schedule-id)
    (ok schedule-id)))

(define-read-only (get-scheduled-event (event-id uint))
  (ok (map-get? scheduled-events event-id)))

(define-read-only (get-time-window (window-id uint))
  (ok (map-get? time-windows window-id)))

(define-read-only (get-appointment-slot (date uint) (slot-id uint))
  (ok (map-get? appointment-slots { date: date, slot-id: slot-id })))

(define-read-only (get-recurring-schedule (schedule-id uint))
  (ok (map-get? recurring-schedules schedule-id)))

(define-read-only (calculate-time-difference (start-time uint) (end-time uint))
  (ok (if (> end-time start-time)
      (- end-time start-time)
      u0)))

(define-read-only (add-days (base-time uint) (days uint))
  (ok (+ base-time (* days SECONDS-PER-DAY))))

(define-read-only (is-time-in-window (check-time uint) (window-start uint) (window-end uint))
  (ok (and (>= check-time window-start) (<= check-time window-end))))

(define-read-only (validate-principal (p principal))
  (principal-destruct? p))

(define-read-only (format-event-id (event-id uint))
  (ok (int-to-ascii event-id)))

(define-read-only (parse-event-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
