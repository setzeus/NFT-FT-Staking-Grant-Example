(define-trait stake-helper-trait
  (
    ;; Get collection custody-status
    (get-collection-custody-status () (response bool uint))

    ;; Get linked NFT principal
    (get-collection-contract () (response principal uint))

    ;; Get local staking data
    (get-local-staking-data (uint) (response (optional {staker: (optional principal), last-staked-or-claimed: uint}) uint))

    ;; Get unclaimed balance
    (get-total-unclaimed-local (principal) (response uint uint))

    ;; Get local stakes
    (get-local-stakes (principal) (response (optional (list 1000 uint)) uint))

    ;; Stake item

    ;; Unstake item

    ;; Claim unclaimed balance
  )
)
