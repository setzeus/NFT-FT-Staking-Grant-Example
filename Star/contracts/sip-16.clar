(define-trait stake-main
  (
    ;; Get team admins
    (get-team-admins () (response (list 10 principal) uint))

    ;; Get whitelisted collections
    (get-whitelisted-collections () (response (list 100 principal) uint))

    ;; Add team admin
    (add-team-admin (principal) (response bool uint))

    ;; Remove team admin

    ;; Add whitelisted collection
    (add-whitelisted-collection (principal) (response bool uint))

    ;; Remove whitelisted collection
  )
)


(define-trait stake-helper
  (
    ;; Get linked NFT principal
    (get-contract () (response principal uint))

    ;; Get collection custody-status
    (get-custody-status () (response bool uint))

    ;; Get staking data
    (get-staking-data (uint) (response (optional {staker: (optional principal), last-staked-or-claimed: uint}) uint))

    ;; Get unclaimed balance
    (get-total-unclaimed (principal) (response uint uint))

    ;; Get local stakes
    (get-all-stakes (principal) (response (optional (list 1000 uint)) uint))

    ;; Stake item
    (stake-item (uint) (response bool uint))

    ;; Unstake item
    (unstake-item (uint) (response bool uint))

    ;; Claim item balance
    (claim-item (uint) (response bool uint))
  )
)

