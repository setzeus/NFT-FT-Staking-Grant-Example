;; nft-staking-a
;; Stacks Grant example contract for NFT(s) -> FT Staking SIP
;; NFT-Staking-A is the helper contract for staking collection-a
;; Written by Setzeus/StrataLabs

;; These contracts act as controllers for the staking of this collection
;; Instead of staking all collections in a centralized staking contract like in Monolith, here, we follow a Star or Wheel/Spoke toplogy

;; Controller Functions
;; Staking -> If custodial this contract should take custody, else 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Cons, Vars, & Maps ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Constant for reference collection (nft-a)
(define-constant nft-a-principal .nft-a)

;; Constant for custodial property for reference collection (nft-a)
(define-constant custody-status true)

;; 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; SIP16(?) Functions ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Get Collection Contract
(define-read-only (get-collection-contract) 
    (ok nft-a-principal)
)

;; Staking
;; @desc - function for custodially staking an NFT, can only be called by the staking contract
;; @param - id:uint - id of the NFT
(define-public (staking (item uint))
    (let
        (
            ;;(item-staking-data (unwrap! (contract-call? .staking get-item-staking-data nft-a-principal item) (err "err-contract-call-get-item-staking-data")))
        )

        ;; Do *not* need to assert that tx-sender == owner or else transfer below will fail
        ;; Send NFT to this contract
        (unwrap! (contract-call? .nft-a transfer item tx-sender (as-contract tx-sender)) (err "err-nft-a-transfer"))

        ;; Update staking data
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
        (if (> (- block-height last-staked-or-claimed) u0)
            (unwrap! (contract-call? .staking claim-rewards nft-a-principal item) (err "err-claim-rewards"))
            (ok true)
        )
    )
)


;; Non-Custodial Staking

