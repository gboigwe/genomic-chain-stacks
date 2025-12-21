;; research-contribution-nft - Clarity 4
;; NFT representing research contributions and participation rewards

(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NFT-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-CLAIMED (err u102))
(define-constant ERR-INVALID-PARAMS (err u103))
(define-constant ERR-CONTRIBUTION-INVALID (err u104))

(define-non-fungible-token research-contribution-nft uint)
(define-data-var nft-counter uint u0)

(define-map contribution-metadata uint
  {
    contributor: principal,
    research-project-id: uint,
    contribution-type: (string-ascii 50),
    data-hash: (buff 64),
    timestamp: uint,
    impact-score: uint,
    is-verified: bool,
    reward-amount: uint
  }
)

(define-map project-contributions { project-id: uint, contributor: principal }
  { total-contributions: uint, last-contribution: uint }
)

(define-map contribution-rewards uint
  { claimed: bool, claim-timestamp: uint, reward-recipient: principal }
)

(define-map verified-projects uint
  { project-name: (string-utf8 100), lead-researcher: principal, is-active: bool }
)

(define-data-var project-counter uint u0)

;; Register a research project
(define-public (register-project (project-name (string-utf8 100)))
  (let ((project-id (+ (var-get project-counter) u1)))
    (map-set verified-projects project-id
      { project-name: project-name, lead-researcher: tx-sender, is-active: true })
    (var-set project-counter project-id)
    (ok project-id)))

;; Mint contribution NFT
(define-public (mint-contribution
    (project-id uint)
    (contribution-type (string-ascii 50))
    (data-hash (buff 64))
    (impact-score uint)
    (reward-amount uint))
  (let
    ((new-id (+ (var-get nft-counter) u1))
     (project (unwrap! (map-get? verified-projects project-id) ERR-CONTRIBUTION-INVALID)))
    (asserts! (get is-active project) ERR-CONTRIBUTION-INVALID)
    (asserts! (<= impact-score u100) ERR-INVALID-PARAMS)
    (try! (nft-mint? research-contribution-nft new-id tx-sender))
    (map-set contribution-metadata new-id
      {
        contributor: tx-sender,
        research-project-id: project-id,
        contribution-type: contribution-type,
        data-hash: data-hash,
        timestamp: stacks-block-time,
        impact-score: impact-score,
        is-verified: false,
        reward-amount: reward-amount
      })
    (map-set contribution-rewards new-id
      { claimed: false, claim-timestamp: u0, reward-recipient: tx-sender })
    (update-project-stats project-id tx-sender)
    (var-set nft-counter new-id)
    (ok new-id)))

;; Transfer NFT
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (nft-get-owner? research-contribution-nft token-id)) ERR-NFT-NOT-FOUND)
    (nft-transfer? research-contribution-nft token-id sender recipient)))

;; Verify contribution
(define-public (verify-contribution (token-id uint))
  (let ((metadata (unwrap! (map-get? contribution-metadata token-id) ERR-NFT-NOT-FOUND))
        (project (unwrap! (map-get? verified-projects (get research-project-id metadata)) ERR-NFT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get lead-researcher project)) ERR-NOT-AUTHORIZED)
    (ok (map-set contribution-metadata token-id (merge metadata { is-verified: true })))))

;; Claim rewards
(define-public (claim-reward (token-id uint))
  (let ((metadata (unwrap! (map-get? contribution-metadata token-id) ERR-NFT-NOT-FOUND))
        (reward-info (unwrap! (map-get? contribution-rewards token-id) ERR-NFT-NOT-FOUND))
        (owner (unwrap! (nft-get-owner? research-contribution-nft token-id) ERR-NFT-NOT-FOUND)))
    (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)
    (asserts! (get is-verified metadata) ERR-CONTRIBUTION-INVALID)
    (asserts! (not (get claimed reward-info)) ERR-ALREADY-CLAIMED)
    (map-set contribution-rewards token-id
      { claimed: true, claim-timestamp: stacks-block-time, reward-recipient: tx-sender })
    (ok (get reward-amount metadata))))

;; Update project contribution statistics
(define-private (update-project-stats (project-id uint) (contributor principal))
  (let ((stats (default-to
                 { total-contributions: u0, last-contribution: u0 }
                 (map-get? project-contributions { project-id: project-id, contributor: contributor }))))
    (map-set project-contributions { project-id: project-id, contributor: contributor }
      { total-contributions: (+ (get total-contributions stats) u1),
        last-contribution: stacks-block-time })
    true))

;; Read-only functions
(define-read-only (get-last-token-id)
  (ok (var-get nft-counter)))

(define-read-only (get-token-uri (token-id uint))
  (ok none))

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? research-contribution-nft token-id)))

(define-read-only (get-contribution-metadata (token-id uint))
  (ok (map-get? contribution-metadata token-id)))

(define-read-only (get-reward-info (token-id uint))
  (ok (map-get? contribution-rewards token-id)))

(define-read-only (get-project-info (project-id uint))
  (ok (map-get? verified-projects project-id)))

(define-read-only (get-contributor-stats (project-id uint) (contributor principal))
  (ok (map-get? project-contributions { project-id: project-id, contributor: contributor })))

;; Clarity 4: principal-destruct?
(define-read-only (validate-contributor (contributor principal))
  (principal-destruct? contributor))

;; Clarity 4: int-to-ascii
(define-read-only (format-token-id (token-id uint))
  (ok (int-to-ascii token-id)))

;; Clarity 4: string-to-uint?
(define-read-only (parse-token-id (id-str (string-ascii 20)))
  (string-to-uint? id-str))

;; Clarity 4: burn-block-height
(define-read-only (get-bitcoin-block)
  (ok burn-block-height))
