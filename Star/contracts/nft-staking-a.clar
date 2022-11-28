;; nft-staking-a
;; Stacks Grant example contract for NFT(s) -> FT Staking SIP
;; NFT-Staking-A is the helper contract for staking collection-a
;; Written by Setzeus/StrataLabs

;; These contracts act as controllers for the staking of this collection
;; Instead of staking all collections in a centralized staking contract like in Monolith, here, we follow a Star or Wheel/Spoke toplogy

;; Controller Functions
;; Staking -> If custodial this contract should take custody, else 

(impl-trait .sip-16.stake-helper-trait)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Cons, Vars, & Maps ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Constant for reference collection (nft-a)
(define-constant nft-a-principal .nft-a)

;; Constant for custodial property for reference collection (nft-a)
(define-constant custody-status true)

;; Map that tracks all IDs staked by user locally
(define-map all-user-stakes principal (list 1000 uint))

;; Map that defines the staking status for an NFT locally
(define-map staking-data uint {
    staker: (optional principal),
    last-staked-or-claimed: uint
})

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; SIP16(?) Functions ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Get Collection Custody-Status
(define-read-only (get-collection-custody-status) 
    (ok custody-status)
)

;; Get Collection Contract
(define-read-only (get-collection-contract) 
    (ok nft-a-principal)
)

;; Get Local Staking Data
(define-read-only (get-local-staking-data (item  uint)) 
    (ok (map-get? staking-data item))
)

;; Get Local User Stakes
(define-read-only (get-local-stakes (user principal)) 
    (ok (map-get? all-user-stakes user))
)

;; Get Total Unclaimed Balance
(define-read-only (get-total-unclaimed-local (user principal)) 
    (let 
        (
            (user-stakes (unwrap! (map-get? all-user-stakes tx-sender) (err u1)))
            (list-of-height-differences (map map-from-list-to-heights user-stakes))
        )
        (ok (fold + list-of-height-differences u0))
    )
)

;; Helper - Map from list of actives stakes to list of height differences
(define-private (map-from-list-to-heights (item uint))
    (- block-height (get last-staked-or-claimed (default-to {staker: (some tx-sender), last-staked-or-claimed: block-height} (map-get? staking-data item))))
)

;; Staking
;; @desc - function for custodially staking an NFT, can only be called by the staking contract
;; @param - id:uint - id of the NFT
(define-public (staking (item uint))
    (let
        (
            ;;(item-staking-data (unwrap! (contract-call? .staking get-item-staking-data nft-a-principal item) (err "err-contract-call-get-item-staking-data")))
            (current-user-stakes (map-get? all-user-stakes tx-sender))
        )

        ;; Do *not* need to assert that tx-sender == owner or else transfer below will fail
        ;; Send NFT to this contract
        (unwrap! (contract-call? .nft-a transfer item tx-sender (as-contract tx-sender)) (err "err-nft-a-transfer"))

        ;; Update local staking data
        (map-set staking-data item {
            staker: (some tx-sender),
            last-staked-or-claimed: block-height
        })

        ;; Update local all user stakes
        (if (is-none current-user-stakes)
            (map-set all-user-stakes tx-sender (list item))
            (map-set all-user-stakes tx-sender (unwrap! (as-max-len? (append (unwrap! current-user-stakes (err "err-no-user-stakes")) item) u1000) (err "err-as-max-len")))
        )

        ;; Update global staking data
        (ok (unwrap! (contract-call? .staking create-stake nft-a-principal custody-status item) (err "err-create-stake")))
    )
)

(define-public (unstake (item uint)) 
    (let 
        (
            (item-staking-data (unwrap! (contract-call? .staking get-item-staking-data nft-a-principal item) (err "err-stake-does-not-exist")))
            (staker (get staker item-staking-data))
            (last-staked-or-claimed (get last-staked-or-claimed item-staking-data))
        )

        ;; Assert that tx-sender == item-staking-data staker
        (asserts! (is-eq (some tx-sender) staker) (err "err-not-staker"))

        ;; Check for unclaimed rewards
        (ok (if (> (- block-height last-staked-or-claimed) u0)
            (unwrap! (contract-call? .staking claim-rewards nft-a-principal item) (err "err-claim-rewards"))
            true
        ))
    )
)


;; Non-Custodial Staking

