(define-trait stake-main
  (
    ;; Get team admins
    (get-team-admins () (response (list 10 principal) uint))

    ;; Get whitelisted collections
    (get-whitelisted-collections () (response (list 100 principal) uint))

    ;; Get max reward per block
    (get-max-reward-per-block () (response uint uint))

    ;; Add team admin
    (add-team-admin (principal) (response bool uint))

    ;; Remove team admin
    (remove-team-admin (principal) (response bool uint))

    ;; Add whitelisted collection
    (add-whitelisted-collection (<stake-helper>) (response bool uint))

    ;; Remove whitelisted collection
    (remove-whitelisted-collection (principal) (response bool uint))

    ;; Update max reward per block
    (update-max-reward-per-block (uint) (response bool uint))
  )
)


(define-trait stake-helper
  (
    ;; Get linked NFT principal
    (get-contract () (response principal uint))

    ;; Get collection multiplier
    (get-multiplier () (response uint uint))

    ;; Get collection custody-status
    (get-custody-status () (response bool uint))

    ;; Get staking data
    (get-staking-data (uint) (response (optional {staker: (optional principal), last-staked-or-claimed: uint}) uint))

    ;; Get unclaimed balance
    (get-total-unclaimed (principal) (response uint uint))

    ;; Get all user stakes
    (get-all-stakes (principal) (response (optional (list 1000 uint)) uint))

    ;; Stake item
    (stake-item (uint) (response bool uint))

    ;; Unstake item
    (unstake-item (uint) (response bool uint))

    ;; Claim item balance
    (claim-item (uint) (response bool uint))

    ;; Update collection multiplier
    (update-multiplier (uint) (response bool uint))

    ;; Update staking data (callable by the FT/sip10 minting from claim)
    ;;(update-staking-data (uint uint) (response bool uint))
  )
)

