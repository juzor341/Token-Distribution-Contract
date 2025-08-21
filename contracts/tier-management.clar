;; Tier Management Contract
;; Define constants
(define-constant protocol-administrator tx-sender)
(define-constant err-admin-only (err u100))
(define-constant err-invalid-echelon (err u101))
(define-constant err-invalid-threshold (err u102))

;; Define data maps
(define-map participant-echelons principal uint)
(define-map echelon-thresholds uint uint)
(define-map advancement-coefficients uint uint)

;; Define public functions
;; Configure echelon threshold requirements (administrator only)
(define-public (configure-echelon-threshold (echelon uint) (threshold-balance uint))
  (begin
    (asserts! (is-eq tx-sender protocol-administrator) err-admin-only)
    (asserts! (and (> echelon u0) (<= echelon u5)) err-invalid-threshold)
    (ok (map-set echelon-thresholds echelon threshold-balance))))

;; Configure advancement coefficient (administrator only)
(define-public (configure-advancement-coefficient (echelon uint) (coefficient uint))
  (begin
    (asserts! (is-eq tx-sender protocol-administrator) err-admin-only)
    (asserts! (and (> echelon u0) (<= echelon u5)) err-invalid-threshold)
    (asserts! (and (>= coefficient u100) (<= coefficient u200)) err-invalid-threshold)
    (ok (map-set advancement-coefficients echelon coefficient))))

;; Advance participant echelon based on qualifying balance
(define-public (advance-participant-echelon (participant principal) (qualifying-balance uint))
  (let (
    (current-echelon (default-to u0 (map-get? participant-echelons participant)))
    (calculated-echelon (calculate-echelon qualifying-balance))
  )
    (begin
      (asserts! (>= calculated-echelon current-echelon) err-invalid-echelon)
      (ok (map-set participant-echelons participant calculated-echelon)))))

;; Calculate adjusted allocation based on participant echelon
(define-public (calculate-adjusted-allocation (participant principal) (base-allocation uint))
  (let (
    (participant-echelon (default-to u0 (map-get? participant-echelons participant)))
    (coefficient (default-to u100 (map-get? advancement-coefficients participant-echelon)))
    (adjusted-allocation (/ (* base-allocation coefficient) u100))
  )
    (ok adjusted-allocation)))

;; Read-only functions
;; Retrieve participant's current echelon
(define-read-only (retrieve-participant-echelon (participant principal))
  (default-to u0 (map-get? participant-echelons participant)))

;; Retrieve echelon threshold requirement
(define-read-only (retrieve-echelon-threshold (echelon uint))
  (default-to u0 (map-get? echelon-thresholds echelon)))

;; Retrieve advancement coefficient
(define-read-only (retrieve-advancement-coefficient (echelon uint))
  (default-to u100 (map-get? advancement-coefficients echelon)))

;; Calculate echelon based on balance
(define-private (calculate-echelon (qualifying-balance uint))
  (if (>= qualifying-balance (default-to u0 (map-get? echelon-thresholds u5)))
    u5
    (if (>= qualifying-balance (default-to u0 (map-get? echelon-thresholds u4)))
      u4
      (if (>= qualifying-balance (default-to u0 (map-get? echelon-thresholds u3)))
        u3
        (if (>= qualifying-balance (default-to u0 (map-get? echelon-thresholds u2)))
          u2
          (if (>= qualifying-balance (default-to u0 (map-get? echelon-thresholds u1)))
            u1
            u0))))))