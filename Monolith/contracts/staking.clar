;; Staking (monolith)
;; Stacks Grant example contract for NFT(s) -> FT Staking SIP
;; This contract is in charge of handling all staking within this example collection ecosystem.
;; Written by Setzeus/StrataLabs

;; FT
;; Example of a teams primary FT
;; Only mintable/distributed through this staking contract

;; NFT-A
;; Example of an existing primary NFT collections
;; Since already launched, it requires a custodial solution
;; Since primary collection, has highest reward-per-block

(use-trait nft-trait .sip-09.nft-trait)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Cons, Vars, & Maps ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;
;; Vars/Cons ;;
;;;;;;;;;;;;;;;

;; @desc - List of principals that represents all allowlisted, actively-staking collections
(define-data-var allowlist-collections-total (list 100 principal) (list))

;; @desc - List of principals that represents all ***custodial*** allowlisted, actively-staking collections
(define-data-var allowlist-collections-custodial (list 50 principal) (list))

;; @desc - List of principals that represents all ***noncustodial*** allowlisted, actively-staking collections
(define-data-var allowlist-collections-noncustodial (list 50 principal) (list))

;; @desc - Uint that represents that *max* possible stake reward per block (a multiplier of u100)
(define-data-var max-payout-per-block uint u1000000)

;; @desc - Var (uint) that keeps track of the *current* (aka maybe people burned) max token supply
(define-data-var token-max-supply (optional uint) none)

;; @desc - List of principals that have admin privileges
(define-data-var admins (list 100 principal) (list tx-sender))


;;; Helper Vars

;; @desc - (temporary) Uint that's used to aggregate when calling "get-unclaimed-balance"
(define-data-var helper-total-unclaimed-balance uint u0)

;; @desc - (temporary) Principal that's used to temporarily hold a collection principal
(define-data-var helper-collection-principal principal tx-sender)

;; @desc - (temporary) List of uints that's used to temporarily hold the output of a map resulting in a list of height differences (aka blocks staked)
(define-data-var helper-height-difference-list (list 10000 uint) (list))

;; @desc - (temporary) Uint that needs to be removed when unstaking
(define-data-var id-being-removed uint u0)


;;; Maps

;; @desc - Map that tracks of a staked item details (value) by collection & ID (key)
(define-map staked-item {collection: principal, id: uint}
  {
    staker: principal,
    last-staked-or-claimed: uint
  }
)

;; @desc - Map that keeps track of allowlisted principal (key) & corresponding multiplier (value)
(define-map collection-multiplier principal uint)

;; @desc - Map that tracks all staked IDs (value) by collection principal (key)
(define-map all-stakes-in-collection principal (list 10000 uint))

;; @desc - Map that tracks all staked IDs in a collection (value) by user & collection & ID (key)
(define-map user-stakes-by-collection {user: principal, collection: principal}
  (list 10000 uint)
)



;;;;;;;;;;;;;;;;
;; Error Cons ;;
;;;;;;;;;;;;;;;;

(define-constant ERR-ALL-MINTED (err u101))
(define-constant ERR-NOT-AUTH (err u102))
(define-constant ERR-NOT-LISTED (err u103))
(define-constant ERR-WRONG-COMMISSION (err u104))
(define-constant ERR-NFT-TRANSFER (err u105))
(define-constant ERR-PARAM-TYPE (err u106))
(define-constant ERR-NOT-ACTIVE (err u107))
(define-constant ERR-NOT-STAKED (err u108))
(define-constant ERR-STAKED-OR-NONE (err u109))
(define-constant ERR-NOT-ALLOWLISTED (err u110))
(define-constant ERR-UNWRAP (err u111))
(define-constant ERR-NOT-OWNER (err u112))
(define-constant ERR-MIN-STAKE-HEIGHT (err u113))
(define-constant ERR-ALREADY-ALLOWLISTED (err u114))
(define-constant ERR-MULTIPLIER (err u115))
(define-constant ERR-UNWRAP-GET-UNCLAIMED-BALANCE-BY-COLLECTION (err u116))
(define-constant ERR-CURRENTLY-STAKED (err u117))
(define-constant ERR-UNWRAP-STAKE-STATUS (err u118))
(define-constant ERR-UNWRAP-FT (err u119))
(define-constant ERR-UNWRAP-NFT (err u120))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Read Functions ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;
;; Active Collections ;;
;;;;;;;;;;;;;;;;;;;;;;;;
;; @desc - Read function that returns the current active collections in a tuple of two lists (custodial & noncustodial)
(define-read-only (active-collections)
    {
        custodial: (var-get allowlist-collections-custodial),
        noncustodial: (var-get allowlist-collections-noncustodial)
    }
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User Total Generation Rate ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @desc - Read function that returns the current generation rate for tx-sender across all actively staked collective assets
(define-read-only (get-total-generation)
  (let
    (
      (list-of-all-collections-with-active-user-stakes (filter filter-out-collections-with-no-stakes (var-get allowlist-collections-total)))
      (list-of-generation-per-collection (map map-from-list-staked-to-generation-per-collection list-of-all-collections-with-active-user-stakes))
    )
    (ok (fold + list-of-generation-per-collection u0))
  )
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User Collection Generation Rate ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @desc - Read function that returns the current generation rate for tx-sender across one specific collection
(define-read-only (get-generation-by-collection (collection <nft-trait>))
  (let
    (
      (this-collection-multiplier (unwrap! (map-get? collection-multiplier (contract-of collection)) ERR-NOT-ALLOWLISTED))
      (collection-staked-by-user-list (get-staked-by-collection-and-user collection))
      (collection-staked-by-user-count (len (unwrap! collection-staked-by-user-list ERR-UNWRAP)))
      (this-collection-multiplier-normalized (/ (* this-collection-multiplier (var-get max-payout-per-block)) u100))
    )

    (ok (* this-collection-multiplier-normalized collection-staked-by-user-count))
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Stakes By Collection ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @desc - Read function that returns a (list uint) of all actively-staked IDs in a collection by tx-sender
(define-read-only (get-staked-by-collection-and-user (collection <nft-trait>))
  (ok (default-to (list) (map-get? user-stakes-by-collection {user: tx-sender, collection: (contract-of collection)})))
)

;;;;;;;;;;;;;;;;;;
;; Staked By ID ;;
;;;;;;;;;;;;;;;;;;
;; @desc - Read function that returns stake details (staker, status, last-staked-or-claimed) in a specific collection & id
(define-read-only (get-stake-details (collection principal) (item-id uint))
  (ok
    (default-to
      {staker: (unwrap! (element-at (var-get admins) u0) (err "err-admin-list-empty")),last-staked-or-claimed: block-height}
      (map-get? staked-item {collection: collection, id: item-id}))
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User Collection Unclaimed Balance ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ra
;; @desc - Read function that outputs a tx-sender total unclaimed balance from a specific collection
(define-read-only (get-unclaimed-balance-by-collection (collection <nft-trait>))
  (let
    (
      (this-collection-multiplier (unwrap! (map-get? collection-multiplier (contract-of collection)) (err u0)))
      (this-collection-stakes-by-user (default-to (list) (map-get? user-stakes-by-collection {user: tx-sender, collection: (contract-of collection)})))
      (list-of-staked-height-differences (map map-from-id-staked-to-height-difference this-collection-stakes-by-user))
      (this-collection-multiplier-normalized (/ (* this-collection-multiplier (var-get max-payout-per-block)) u100))
    )

      ;; Assert at least one stake exists
      (asserts! (and (> (len this-collection-stakes-by-user) u0) (> (len list-of-staked-height-differences) u0)) (err u0))

      ;; Var-set helper-collection-principal for use in map-from-id-staked-to-height-difference
     ;; (var-set helper-collection-principal (contract-of collection))

      ;; Unclaimed $SNOW balance by user in this collection
      ;; Fold to aggregate total blocks staked across all IDs, then multiply collection multiplier
      (ok (* this-collection-multiplier-normalized (fold + list-of-staked-height-differences u0)))
  )
)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Stake Functions ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; @desc - Universal staking function for staking a specific ID in a collection
;; @param - collection - <nft-trait> - The collection to stake in, id - uint - The ID to stake
(define-public (stake (collection <nft-trait>) (id uint))
  (let
    (
      (current-all-staked-in-collection-list (default-to (list) (map-get? all-stakes-in-collection (contract-of collection))))
      (is-unstaked-in-all-staked-ids-list (index-of current-all-staked-in-collection-list id))
      (is-unstaked-in-staked-by-user-list (index-of (default-to (list) (map-get? user-stakes-by-collection {user: tx-sender, collection: (contract-of collection)})) id))
      (is-unstaked-in-item-details (map-get? staked-item {collection: (contract-of collection), id: id}))
      (current-nft-owner (unwrap-panic (contract-call? collection get-owner id)))
    )

    ;; Assert collection is whitelisted
    (asserts! (is-some (index-of (var-get allowlist-collections-total) (contract-of collection))) ERR-NOT-ALLOWLISTED)

    ;; Assert caller is current owner of NFT
    (asserts! (is-eq (some tx-sender) current-nft-owner) ERR-NOT-OWNER)

    ;; Asserts item is unstaked across all necessary storage
    (asserts! (and (is-none is-unstaked-in-all-staked-ids-list) (is-none is-unstaked-in-staked-by-user-list) (is-none is-unstaked-in-item-details)) ERR-STAKED-OR-NONE)

    ;; Check whether collection is custodial or non-custodial
    (if (is-some (index-of (var-get allowlist-collections-custodial) (contract-of collection)))
       ;; Collection is custodial, owner needs to transfer
        (unwrap! (contract-call? collection transfer id tx-sender (as-contract tx-sender)) ERR-NFT-TRANSFER)
        
       ;; Collection is not custodial, need to flip stake property in contract
        false
    )


    ;; Var set all staked ids list
    (map-set all-stakes-in-collection (contract-of collection)
      (unwrap! (as-max-len? (append (default-to (list) (map-get? all-stakes-in-collection (contract-of collection))) id) u10000) ERR-UNWRAP)
    )

    ;; Map set user staked in collection list
    (map-set user-stakes-by-collection {user: tx-sender, collection: (contract-of collection)}
        (unwrap! (as-max-len? (append (default-to (list) (map-get? user-stakes-by-collection {user: tx-sender, collection: (contract-of collection)})) id) u10000) ERR-UNWRAP)
    )

    ;; Map set staked-item details
    (ok (map-set staked-item {collection: (contract-of collection), id: id}
      {
        staker: tx-sender,
        last-staked-or-claimed: block-height
      }
    ))
  )
)

;; @desc - Universal staking function for a single collection & multiple IDs
;; @param - collection - <nft-trait> - The collection to stake in, ids - (list uint) - The IDs to stake
;; (define-public (stake-multiple (collection <nft-trait>) (ids (list 100 uint)))
;;   (let
;;     (
;;       (current-all-staked-in-collection-list (default-to (list) (map-get? all-stakes-in-collection (contract-of collection))))
;;       (current-staked-by-user-list (default-to (list) (map-get? user-stakes-by-collection {user: tx-sender, collection: (contract-of collection)})))
;;       ;;(all-staked-in-collection-list-fold )
;;       ;;(current-stake-details-map (map-get? staked-item {collection: (contract-of collection), id: id}))
;;       ;;(current-nft-owner (unwrap-panic (contract-call? collection get-owner id)))
;;     )

;;     ;; Assert collection is whitelisted
;;     (asserts! (is-some (index-of (var-get allowlist-collections-total) (contract-of collection))) ERR-NOT-ALLOWLISTED)

;;     ;; Assert caller is current owner of NFT
;;    ;; (asserts! (is-eq (some tx-sender) current-nft-owner) ERR-NOT-OWNER)

;;     ;; Check whether collection is custodial or non-custodial
;;     ;; (if (is-some (index-of (var-get allowlist-collections-custodial) (contract-of collection)))
;;     ;;    ;; Collection is custodial, owner needs to transfer
;;     ;;     (unwrap! (contract-call? collection transfer id tx-sender (as-contract tx-sender)) ERR-NFT-TRANSFER)
        
;;     ;;    ;; Collection is not custodial, need to flip stake property in contract
;;     ;;     false
;;     ;; )

;;     ;; Var set all staked ids list
;;     ;; (map-set all-stakes-in-collection (contract-of collection)
;;     ;;   (unwrap! (as-max-len? (append current-all-staked-in-collection-list ids) u10000) ERR-UNWRAP)
;;     ;; )

;;     ;; Map set user staked in collection list
;;     ;; (map-set user-stakes-by-collection {user: tx-sender, collection: (contract-of collection)}
;;     ;;     (unwrap! (as-max-len? (append current-staked-by-user-list ids) u10000) ERR-UNWRAP)
;;     ;; )

;;     ;; Map set staked-item details
;;     (ok (map-set staked-item {collection: (contract-of collection), id: u0}
;;       {
;;         staker: tx-sender,
;;         last-staked-or-claimed: block-height
;;       }
;;     ))
;;   )
;; )

;; For every item need to check staked-item map & all-stakes-in-collection map


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Claim Functions ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; @desc - Function that a user calls to claim any generated stake rewards for a specific collection & specific id
;; @param - collection - <nft-trait> - The collection to claim from, id - uint - The ID to claim
(define-public (claim-item-stake (collection-collective <nft-trait>) (staked-id uint))
  (let
    (
      (this-collection-multiplier (default-to u0 (map-get? collection-multiplier (contract-of collection-collective))))
      (this-collection-multiplier-normalized (/ (* this-collection-multiplier (var-get max-payout-per-block)) u100))
      (current-staker (get staker (default-to {last-staked-or-claimed: block-height, staker: tx-sender} (map-get? staked-item {collection: (contract-of collection-collective), id: staked-id}))))
      (last-claimed-or-staked-height (get last-staked-or-claimed (default-to {last-staked-or-claimed: block-height, staker: tx-sender} (map-get? staked-item {collection: (contract-of collection-collective), id: staked-id}))))
      (current-nft-owner (unwrap! (contract-call? collection-collective get-owner staked-id) ERR-NOT-AUTH))
      (blocks-staked (- block-height last-claimed-or-staked-height))
    )

    ;; assert collection-collective is active/whitelisted
    (asserts! (is-some (index-of (var-get allowlist-collections-total) (contract-of collection-collective))) ERR-NOT-ALLOWLISTED)                                     

    ;; asserts is staked
    ;;(asserts! stake-status ERR-NOT-STAKED)

    ;; asserts tx-sender is owner && asserts tx-sender is staker
    (asserts! (and (is-eq tx-sender current-staker)) ERR-NOT-OWNER)

    ;; asserts height-difference > 0
    (asserts! (> blocks-staked u0) ERR-MIN-STAKE-HEIGHT)

    ;; contract call to mint for X amount
    (unwrap! (contract-call? .ft mint (* this-collection-multiplier-normalized blocks-staked) tx-sender) ERR-UNWRAP)

    ;; update last-staked-or-claimed height
    (ok (map-set staked-item {collection: (contract-of collection-collective), id: staked-id}
      {
        last-staked-or-claimed: block-height,
        staker: tx-sender
      }
    ))
  )
)

;; @desc - Function that a user calls to claim any generated stake rewards for a specific *collection*
;; @param - collection - <nft-trait> - The collection to claim from
(define-public (claim-collection-stake (collection-collective <nft-trait>))
  (let
    (
      (unclaimed-balance-by-collection (unwrap! (get-unclaimed-balance-by-collection collection-collective) ERR-UNWRAP))
    )

    ;; contract call to mint for X amount
    (unwrap! (contract-call? .ft mint unclaimed-balance-by-collection tx-sender) ERR-UNWRAP)

    ;; Set collection helper var for folding through height differences
    (var-set helper-collection-principal (contract-of collection-collective))

    ;; need to update last-staked-or-claimed from every ID just claimed...
    ;; map from ID staked, don't care of output just update all stake details
    (ok (map map-to-reset-all-ids-staked-by-user-in-this-collection (default-to (list) (map-get? user-stakes-by-collection {user: tx-sender, collection: (contract-of collection-collective)}))))
  )
)

;; @desc -Function that a user calls to stake any current or future SGC asset for $SNOW
;; @param - Collection (principal or collection?), ID (uint) -> bool?
(define-public (claim-all-stake)
  (let
    (
      (list-of-collections-with-active-user-stakes (filter filter-out-collections-with-no-stakes (var-get allowlist-collections-total)))
      (unclaimed-balance-total (unwrap! (get-unclaimed-balance) ERR-UNWRAP))
    )

    ;; contract call to mint for X amount
    (unwrap! (contract-call? .ft mint unclaimed-balance-total tx-sender) ERR-UNWRAP)

    ;; loop through collections, then through IDs, reset last-staked-or-claimed value for each staked ID in each collection by user
    (ok (map map-to-loop-through-active-collection list-of-collections-with-active-user-stakes))
  )
)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Unstake Functions ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (unstake-item (collection <nft-trait>) (staked-id uint))
  (let
    (
      (this-collection-multiplier (default-to u0 (map-get? collection-multiplier (contract-of collection))))
      (this-collection-multiplier-normalized (/ (* this-collection-multiplier (var-get max-payout-per-block)) u100))
      (current-staker (get staker (default-to {last-staked-or-claimed: block-height, staker: tx-sender} (map-get? staked-item {collection: (contract-of collection), id: staked-id}))))
      (last-claimed-or-staked-height (get last-staked-or-claimed (default-to {last-staked-or-claimed: block-height, staker: tx-sender} (map-get? staked-item {collection: (contract-of collection), id: staked-id}))))
      ;;(current-nft-owner (unwrap! (contract-call? collection get-owner staked-id) ERR-NOT-AUTH))
      (blocks-staked (- block-height last-claimed-or-staked-height))
      (current-all-staked-in-collection-list (default-to (list) (map-get? all-stakes-in-collection (contract-of collection))))
      (current-user-staked-by-collection-list (default-to (list) (map-get? user-stakes-by-collection {user: tx-sender, collection: (contract-of collection)})))
    )

    ;; asserts tx-sender is owner && asserts tx-sender is staker
    (asserts! (is-eq tx-sender current-staker) ERR-NOT-OWNER)

    ;; check if blocks-staked > 0 to see if there's any unclaimed $SNOW to claim
    (if (> blocks-staked u0)

      ;; if there is, need to claim unstaked
      (unwrap! (contract-call? .ft mint (* this-collection-multiplier-normalized blocks-staked) tx-sender) ERR-UNWRAP-FT)

      ;; if not, proceed
      true
    )

    
  
    ;; check if collection is in allowlist-collections-custodial
    (if (is-some (index-of (var-get allowlist-collections-custodial) (contract-of collection)))

      ;; if so, transfer NFT back to tx-sender
      (as-contract (unwrap! (contract-call? collection transfer staked-id tx-sender current-staker) ERR-UNWRAP-NFT))

      ;; if not, proceed
      true
    )

    ;; Set helper id for removal in filters below
    (var-set id-being-removed staked-id)

    ;; filter/remove staked-id from all-stakes-in-collection
    (map-set all-stakes-in-collection (contract-of collection) (filter is-not-id current-all-staked-in-collection-list))

    ;; filter/remove staked-id from user-stakes-by-collection
    (map-set user-stakes-by-collection {user: tx-sender, collection: (contract-of collection)} (filter is-not-id current-user-staked-by-collection-list))

    ;; update last-staked-or-claimed height
    (ok (map-set staked-item {collection: (contract-of collection), id: staked-id}
      {
        last-staked-or-claimed: block-height,
        staker: tx-sender
      }
    ))

  )
)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Admin Functions ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; @desc - Function that only an admin user can call to add a new SGC collection for staking
;; @param - Collection (principal or collection?), Collection-Multiple (uint)
(define-public (admin-add-new-collection (collection <nft-trait>) (collection-multiple uint) (custodial bool))
  (let
    (
      (active-whitelist-total (var-get allowlist-collections-total))
      (active-whitelist-custodial (var-get allowlist-collections-custodial))
      (active-whitelist-noncustodial (var-get allowlist-collections-noncustodial))
      (current-admin-list (var-get admins))
      (caller-principal-position-in-list (index-of current-admin-list tx-sender))
    )

    ;;(asserts! (is-some (index-of (var-get admins) tx-sender)) (err u40))
    (asserts! (is-some caller-principal-position-in-list) ERR-NOT-AUTH)

    ;; assert collection not already added
    (asserts! (is-none (index-of active-whitelist-total (contract-of collection))) ERR-ALREADY-ALLOWLISTED)

    ;; assert multiple < 100
    (asserts! (and (< collection-multiple u101) (> collection-multiple u0)) ERR-MULTIPLIER)

    ;; update collection-multiplier map
    (map-set collection-multiplier (contract-of collection) collection-multiple)

    (if custodial
        ;; Is custodial
        (var-set allowlist-collections-custodial (unwrap! (as-max-len? (append active-whitelist-custodial (contract-of collection)) u50) ERR-UNWRAP) )
        ;; Is non-custodial
        (var-set allowlist-collections-noncustodial (unwrap! (as-max-len? (append active-whitelist-noncustodial (contract-of collection)) u50) ERR-UNWRAP) )
    )

    ;; add new principle to whitelist
    (ok (var-set allowlist-collections-total (unwrap! (as-max-len? (append active-whitelist-total (contract-of collection)) u100) ERR-UNWRAP) ))

  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Add Admin Address For Whitelisting ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @desc - Function for add principals that have explicit permission to add current or future stakeable collections
;; @param - Principal that we're adding as whitelist, initially only admin-one has permission
(define-public (add-admin-address-for-whitelisting (new-whitelist principal))
  (let
    (
      (current-admin-list (var-get admins))
      (caller-principal-position-in-list (index-of current-admin-list tx-sender))
      (param-principal-position-in-list (index-of current-admin-list new-whitelist))
    )

    ;; asserts tx-sender is an existing whitelist address
    (asserts! (is-some caller-principal-position-in-list) ERR-NOT-AUTH)

    ;; asserts param principal (new whitelist) doesn't already exist
    (asserts! (is-none param-principal-position-in-list) ERR-ALREADY-ALLOWLISTED)

    ;; append new whitelist address
    (ok (as-max-len? (append (var-get admins) new-whitelist) u100))
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Remove Admin Address For Whitelisting ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @desc - Function for removing principals that have explicit permission to add current or future stakeable collections
;; @param - Principal that we're adding removing as white
(define-public (remove-admin-address-for-whitelisting (remove-whitelist principal))
  (let
    (
      (current-admin-list (var-get admins))
      (caller-principal-position-in-list (index-of current-admin-list tx-sender))
      (removeable-principal-position-in-list (index-of current-admin-list remove-whitelist))
    )

    ;; asserts tx-sender is an existing whitelist address
    (asserts! (is-some caller-principal-position-in-list) ERR-NOT-AUTH)

    ;; asserts param principal (removeable whitelist) already exist
    (asserts! (is-eq removeable-principal-position-in-list) ERR-NOT-ALLOWLISTED) ;;changed error to make sense, changed is-some to is-eq

    ;; temporary var set to help remove param principal
    (var-set helper-collection-principal remove-whitelist)

    ;; need to remove from custodial or noncustodial as well...

    ;; filter existing whitelist address
    (ok (filter is-not-removeable (var-get admins)))
  )
)

;; @desc - Helper function for removing a specific admin from tne admin whitelist
(define-private (is-not-removeable (admin-principal principal))
  (not (is-eq admin-principal (var-get helper-collection-principal)))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Admin Manual Unstake ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @desc - Function for emergency un-staking all manually custodied assets (Stacculents or Spookies)
;; @param - Principal of collection we're removing, ID of item we're manually unstaking & returning to user
(define-public (admin-emergency-unstake (collection <nft-trait>) (id uint)) 
  (let 
    (
      (this-collection-multiplier (default-to u0 (map-get? collection-multiplier (contract-of collection))))
      (this-collection-multiplier-normalized (/ (* this-collection-multiplier (var-get max-payout-per-block)) u100))
      (original-owner (get staker (default-to {last-staked-or-claimed: block-height, staker: tx-sender} (map-get? staked-item {collection: (contract-of collection), id: id}))))
      (last-claimed-or-staked-height (get last-staked-or-claimed (default-to {last-staked-or-claimed: block-height, staker: tx-sender} (map-get? staked-item {collection: (contract-of collection), id: id}))))
      (current-owner (unwrap! (contract-call? collection get-owner id) ERR-NOT-AUTH))
      (blocks-staked (- block-height last-claimed-or-staked-height))
    ) 
    
    ;; check if collection is custodial / noncustodial & deal accordingly

    ;; asserts that item is actively staked
    ;;(asserts! stake-status ERR-NOT-STAKED)

    ;; asserts that contract is current owner & that staker/original owner is *not* contract
    (asserts! (and (is-eq (some (as-contract tx-sender)) current-owner) (not (is-eq (as-contract  tx-sender) original-owner))) ERR-NOT-OWNER)

    ;; check for any owed generated rewards
    (if (> blocks-staked u0) 
      (unwrap! (contract-call? .ft mint (* this-collection-multiplier-normalized blocks-staked) tx-sender) ERR-UNWRAP)
      true
    )

    ;; unstake item 

    ;; send item back to original owner
    (ok true)
  )
)

;; @desc - Function that only an admin user can call to add a new SGC collection for staking
;; @param - Collection (principal or collection?), Collection-Multiple (uint)
(define-private (get-token-max-supply)
  (match (var-get token-max-supply)
    returnTokenMaxSupply returnTokenMaxSupply
    (let
      (
        (new-token-max-supply (unwrap! (contract-call? .ft get-max-supply) u0))
      )
      (var-set token-max-supply (some new-token-max-supply))
      new-token-max-supply
    )
  )
)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Private Functions ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; @desc - Filter function used which takes in all (list principal) stakeable/allowlist principals & outputs a (list principal) of actively-staked (by tx-sender) principals
(define-private (filter-out-collections-with-no-stakes (collection principal))
  (let
    (
      (collection-staked-by-user-list (default-to (list) (map-get? user-stakes-by-collection {user: tx-sender, collection: collection})))
      (collection-staked-by-user-count (len collection-staked-by-user-list))
    )
    (if (>= collection-staked-by-user-count u0)
      true
      false
    )
  )
)

;; @desc - Map function which takes in a list of actively-staked principals & returns a list of current generation rate per collection
(define-private (map-from-list-staked-to-generation-per-collection (collection principal))
  (let
    (
      (this-collection-multiplier (default-to u0 (map-get? collection-multiplier collection)))
      (collection-staked-by-user-list (default-to (list) (map-get? user-stakes-by-collection {user: tx-sender, collection: collection})))
      (collection-staked-by-user-count (len collection-staked-by-user-list))
      (this-collection-multiplier-normalized (/ (* this-collection-multiplier (var-get max-payout-per-block)) u100))
    )
    (* this-collection-multiplier-normalized collection-staked-by-user-count)
  )
)

;; @desc - Read function that returns the tx-sender's total unclaimed balance across all allowlisted collections
(define-private (get-unclaimed-balance)
  (let
    (
      ;; Filter from (list principal) of all allowlist principals/NFTs to (list principal) of all allowlist principals/NFTs where user has > 0 stakes
      (this-collection-stakes-by-user (filter filter-out-collections-with-no-stakes (var-get allowlist-collections-total)))
      (list-of-height-differences (list))
    )

    ;; (done) 1. Filter from allowlisted to active staked
    ;; 2. Map from a list of active staked (principals) to a list of unclaimed balance per collection (uint)
    ;; 3. Fold & add all unclaimed balance per collection (uint) to get total unclaimed balance (uint)



    ;; 1. Filter from allowlisted to active staked
    ;; 2. Map from a list of principals to a list of uints

    ;; clear temporary unclaimed balance uint
    (var-set helper-total-unclaimed-balance u0)

    ;; map through this-collection-stakes-by-user, don't care about output list, care about appending to list-of-height-differences
    (map map-to-append-to-list-of-height-differences this-collection-stakes-by-user)

    ;; return unclaimed balance from tx-sender
    (ok (var-get helper-total-unclaimed-balance))
  )
)

;; @desc - looping through all the collections that a user *does* have active stakes, goal of this function is to append the unclaimed balance from each collection to a new list (helper-height-difference)
(define-private (map-to-append-to-list-of-height-differences (collection principal))
  (let
    (
      (this-collection-multiplier (default-to u0 (map-get? collection-multiplier collection)))
      (this-collection-stakes-by-user (default-to (list) (map-get? user-stakes-by-collection {user: tx-sender, collection: collection})))
      (this-collection-multiplier-normalized (/ (* this-collection-multiplier (var-get max-payout-per-block)) u100))
    )

    ;; set helper list to empty
    (var-set helper-height-difference-list (list))

    ;; Set collection helper var for folding through height differences
    (var-set helper-collection-principal collection)

    ;; Use map as a loop to append helper list with get-unclaimed-balance-by-collection
    (map append-helper-list-from-id-staked-to-height-difference this-collection-stakes-by-user)

    ;; Total unclaimed balance in collection
    (var-set helper-total-unclaimed-balance
      (+
        (var-get helper-total-unclaimed-balance)
        (* this-collection-multiplier-normalized (fold + (var-get helper-height-difference-list) u0))
      )
    )

    tx-sender
  )
)

;; @desc - function to append the height-difference
(define-private (append-helper-list-from-id-staked-to-height-difference (staked-id uint))
  (let
    (
      (staked-or-claimed-height (get last-staked-or-claimed (default-to {last-staked-or-claimed: block-height, staker: tx-sender} (map-get? staked-item {collection: (var-get helper-collection-principal), id: staked-id}))))
      (height-difference (- block-height staked-or-claimed-height))
    )

    (var-set helper-height-difference-list
      (unwrap! (as-max-len? (append (var-get helper-height-difference-list) height-difference) u1000) u0)
    )
    u1
  )
)

;; @desc - Helper function used to map from a list of uint of staked ids to a list of uint of height-differences
(define-private (map-from-id-staked-to-height-difference (staked-id uint))
  (let
    (
      (staked-or-claimed-height (get last-staked-or-claimed (default-to {last-staked-or-claimed: block-height, staker: tx-sender} (map-get? staked-item {collection: (var-get helper-collection-principal), id: staked-id}))))
    )
    (print (- block-height staked-or-claimed-height))
    (- block-height staked-or-claimed-height)
  )
)

(define-private (map-to-reset-all-ids-staked-by-user-in-this-collection (staked-id uint))
  (begin
    (map-set staked-item {collection: (var-get helper-collection-principal), id: staked-id}
      (merge
        (default-to {last-staked-or-claimed: block-height, staker: tx-sender} (map-get? staked-item {collection: (var-get helper-collection-principal), id: staked-id}))
        {last-staked-or-claimed: block-height}
      )
    )
    u1
  )
)

(define-private (map-to-loop-through-active-collection (collection principal))
  (let
    (
      (collection-staked-by-user-list (default-to (list) (map-get? user-stakes-by-collection {user: tx-sender, collection: collection})))
    )
      (map map-to-set-reset-last-claimed-or-staked-height collection-staked-by-user-list)
      tx-sender
  )
)

(define-private (map-to-set-reset-last-claimed-or-staked-height (staked-id uint))
  (begin
    (map-set staked-item {collection: (var-get helper-collection-principal), id: staked-id}
      (merge
        (default-to {last-staked-or-claimed: block-height, staker: tx-sender} (map-get? staked-item {collection: (var-get helper-collection-principal), id: staked-id}))
        {last-staked-or-claimed: block-height}
      )
    )
    u0
  )
)

(define-private (is-not-id (list-id uint))
  (not (is-eq list-id (var-get id-being-removed)))
)