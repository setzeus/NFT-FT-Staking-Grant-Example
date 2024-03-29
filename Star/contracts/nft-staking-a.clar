;; nft-staking-a
;; Stacks Grant example contract for NFT(s) -> FT Staking SIP
;; NFT-Staking-A is the helper contract for staking collection-a
;; Written by Setzeus/StrataLabs

;; These contracts act as controllers for the staking of this collection
;; Instead of staking all collections in a centralized staking contract like in Monolith, here, we follow a Star or Wheel/Spoke toplogy

;; Controller Functions
;; Staking -> If custodial this contract should take custody, else 

(impl-trait .sip-16.stake-helper)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Cons, Vars, & Maps ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Constant for reference collection (nft-a)
(define-constant nft-a-principal .nft-a)

;; Constant for custodial property for reference collection (nft-a)
(define-constant custody-status true)

;; Var that tracks current collection multiplier
(define-data-var collection-multiplier uint u1)

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

;; Get Collection Contract
(define-read-only (get-contract) 
    (ok nft-a-principal)
)

;; Get Collection Multiplier
(define-read-only (get-multiplier) 
    (ok (var-get collection-multiplier))
)

;; Get Collection Custody Status
(define-read-only (get-custody-status) 
    (ok custody-status)
)

;; Get Staking Data
(define-read-only (get-staking-data (item  uint)) 
    (ok (map-get? staking-data item))
)

;; Get Local User Stakes
(define-read-only (get-all-stakes (user principal)) 
    (ok (map-get? all-user-stakes user))
)

;; Get Total Unclaimed Balance
(define-read-only (get-total-unclaimed (user principal)) 
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
(define-public (stake-item (item uint))
    (let
        (
            ;;(item-staking-data (unwrap! (contract-call? .staking get-item-staking-data nft-a-principal item) (err "err-contract-call-get-item-staking-data")))
            (current-item-staking-data (unwrap! (get-staking-data item) (err u100)))
            (current-user-stakes (map-get? all-user-stakes tx-sender))
            (current-nft-owner (unwrap! (contract-call? .nft-a get-owner item) (err u101)))
        )

        ;; Send NFT to this contract
        (unwrap! (contract-call? .nft-a transfer item tx-sender (as-contract tx-sender)) (err u102))

        ;; Update local staking data
        (map-set staking-data item {
            staker: (some tx-sender),
            last-staked-or-claimed: block-height
        })

        ;; Update local all user stakes
        (ok (if (is-none current-user-stakes)
            (map-set all-user-stakes tx-sender (list item))
            (map-set all-user-stakes tx-sender (unwrap! (as-max-len? (append (unwrap! current-user-stakes (err u301)) item) u1000) (err u302)))
        ))
    )
)

(define-public (unstake-item (item uint)) 
    (let 
        (
            (item-staking-data (unwrap! (get-staking-data item) (err u400)))
            (staker (get staker item-staking-data))
            (last-staked-or-claimed (unwrap! (get last-staked-or-claimed item-staking-data) (err u401)))
        )

        ;; Assert that tx-sender == item-staking-data staker
        (asserts! (is-eq (some (some tx-sender)) staker) (err u402))

        ;; Check for unclaimed rewards
        (ok (if (> (- block-height last-staked-or-claimed) u0)
            false
            ;;(unwrap! (contract-call? .staking claim-rewards nft-a-principal item) (err u403))
            true
        ))
    )
)


;; Claim Item Balance
;; @desc - function for claiming the balance of an NFT staked
;; @param - id:uint - id of the NFT
(define-public (claim-item (item uint))
    (ok true)
)

;; Update Collection Multiplier
;; @desc - function for updating the collection multiplier
;; @param - multiplier:uint - new multiplier
(define-public (update-multiplier (multiplier uint))
    ;; assert multiple < 100
    ;;(asserts! (and (< collection-multiple u101) (> collection-multiple u0)) (err u202))
    (ok (var-set collection-multiplier multiplier))
)