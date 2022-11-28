(define-trait stake-helper-trait
  (
    ;; Get collection custody-status
    (get-collection-custody-status () (response bool uint))

    ;; Get linked NFT principal
    (get-collection-contract () (response principal uint))

    ;; URI for metadata associated with the token
    (get-local-staking-data (uint) (response (optional {staker: (optional principal), last-staked-or-claimed: uint}) uint))

    (get-total-unclaimed-local (principal) (response uint uint))

    (get-local-stakes (principal) (response (optional (list 1000 uint)) uint))
  )
)
