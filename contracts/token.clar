;; Token Distribution Contract
;; Define the fungible token for distributed rewards
(define-fungible-token nexus-token)

;; Define constants
(define-constant protocol-administrator tx-sender)
(define-constant err-admin-only (err u100))
(define-constant err-unauthorized-distributor (err u101))
(define-constant err-insufficient-allocation (err u102))

;; Define data variables
(define-map authorized-distributors principal bool)
(define-map locked-allocations principal uint)
(define-map locking-initiation-height principal uint)

;; Define public functions
;; Authorize distribution entity
(define-public (authorize-distributor (distributor principal))
  (begin
    (asserts! (is-eq tx-sender protocol-administrator) err-admin-only)
    (ok (map-set authorized-distributors distributor true))))

;; Mint and allocate tokens to participant
(define-public (mint-and-allocate (recipient principal) (allocation-amount uint))
  (begin
    (asserts! (is-authorized-distributor tx-sender) err-unauthorized-distributor)
    (ft-mint? nexus-token allocation-amount recipient)))

;; Redeem tokens for protocol benefits
(define-public (redeem-allocation (redemption-amount uint))
  (begin
    (asserts! (>= (stx-get-balance tx-sender) redemption-amount) err-insufficient-allocation)
    (ft-burn? nexus-token redemption-amount tx-sender)))

;; Lock tokens for enhanced yield generation
(define-public (lock-allocation (lock-amount uint))
  (let ((current-locked (default-to u0 (map-get? locked-allocations tx-sender))))
    (begin
      (asserts! (>= (stx-get-balance tx-sender) lock-amount) err-insufficient-allocation)
      (map-set locked-allocations tx-sender (+ current-locked lock-amount))
      (map-set locking-initiation-height tx-sender block-height)
      (ft-burn? nexus-token lock-amount tx-sender))))

;; Unlock tokens and claim yield enhancement
(define-public (unlock-allocation)
  (let (
    (locked-amount (default-to u0 (map-get? locked-allocations tx-sender)))
    (initiation-height (default-to u0 (map-get? locking-initiation-height tx-sender)))
    (locking-duration (- block-height initiation-height))
    (yield-rate u1) ;; 1% enhancement per 100 blocks
    (yield-enhancement (/ (* locked-amount locking-duration yield-rate) u10000))
  )
    (begin
      (map-delete locked-allocations tx-sender)
      (map-delete locking-initiation-height tx-sender)
      (ft-mint? nexus-token (+ locked-amount yield-enhancement) tx-sender))))

;; Read-only functions
;; Verify authorized distributor status
(define-read-only (is-authorized-distributor (address principal))
  (default-to false (map-get? authorized-distributors address)))

;; Retrieve locked allocation balance
(define-read-only (retrieve-locked-allocation (address principal))
  (default-to u0 (map-get? locked-allocations address)))

;; Retrieve locking initiation height
(define-read-only (retrieve-locking-initiation-height (address principal))
  (default-to u0 (map-get? locking-initiation-height address)))