;; Staking (star)
;; Stacks Grant example contract for NFT(s) -> FT Staking SIP
;; This contract is in charge of most, but not all staking operations as decentralizes the monolith staking example
;; Written by Setzeus/StrataLabs

(use-trait nft-trait .sip-09.nft-trait)
(use-trait stake-helper-trait .sip-16.stake-helper)
(impl-trait .sip-16.stake-main)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Cons, Vars, & Maps ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; List of all team admins
(define-data-var team-admins (list 10 principal) (list))

;; List of all whitelisted collections
(define-data-var whitelisted-collections (list 100 principal) (list ))

;; ;; List of custodial collections
(define-data-var whitelist-custodial (list 50 principal) (list ))

;; ;; List of non-custodial collections
(define-data-var whitelist-noncustodial (list 50 principal) (list ))

;; ;; List of principals that are whitelisted/have admin privileges
;; (define-data-var whitelist-admins (list 10 principal) (list tx-sender))

;; ;; @desc - Uint that represents that *max* possible stake reward per block (a multiplier of u100)
;; (define-data-var max-payout-per-block uint u1000000)

;; @desc - Map that keeps track of whitelisted principal (key) & corresponding multiplier (value)
(define-map collection-multiplier principal uint)

;; ;; Var for helping principals with list
;; (define-data-var helper-principal principal tx-sender)

;; ;; Map that defines the staking status for an NFT globally
;; (define-map staking-data {collection: principal, item: uint} {
;;     staker: (optional principal),
;;     last-staked-or-claimed: uint
;; })

;; ;; Map that tracks all staked IDs in a collection (value) by user & collection & ID (key)
;; (define-map user-stakes-by-collection {user: principal, collection: principal}
;;   (list 10000 uint)
;; )

;; ;;;;;;;;;;;;;;;;;;;;;;;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;
;; ;;;;;; SIP16 Main ;;;;;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;

;; Get team admins
(define-read-only (get-team-admins)
  (ok (var-get team-admins))
)

;; Get whitelisted collections
(define-read-only (get-whitelisted-collections)
  (ok (var-get whitelisted-collections))
)


;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;;;;;; Read Functions ;;;;;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; ;; Get Active Collections
;; (define-read-only (get-active-collections)
;;     (var-get whitelist-total)
;; )

;; ;; Get Item Staking Data
;; (define-read-only (get-item-staking-data (collection principal) (item uint)) 
;;     (map-get? staking-data {collection: collection, item: item})
;; )

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;; Get Total Unclaimed Balance ;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;; Calculates the current unclaimed balance for a user across all whitelisted collections
;; (define-read-only (get-total-unclaimed-balance) 
;;   (let 
;;     (
;;       (list-of-all-collections-with-active-user-stakes (filter filter-out-collections-with-no-stakes (var-get whitelist-total)))
;;       (list-of-unclaimed-balances (list))
;;     )
;;     (ok list-of-all-collections-with-active-user-stakes)
;;   )
;; ) 

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;; Get Collection Unclaimed Balance ;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; (define-read-only (get-collection-unclaimed-balance (collection <stake-helper-trait>))
;;   (let
;;     (
;;       (this-collection-multiplier (unwrap! (map-get? collection-multiplier (contract-of collection)) (err "err-collection-has-no-multiplier")))
;;       (this-collection-stakes-by-user (unwrap! (map-get? user-stakes-by-collection {user: tx-sender, collection: (contract-of collection)}) (err "err-user-has-no-stakes")))
;;       ;;(list-of-unclaimed-balance-per-item )
;;     )
;;     (ok true)
;;   )
;; )

;; ;; Map from collection IDs to collection height differences / unclaimed balance
;; ;; (define-private (map-from-ids-to-heights (item uint)) 
;; ;;   (staked-or-claimed-height (get last-staked-or-claimed (unwrap! (map-get? staking-data {collection: collection, item: item}))))
;; ;; )

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;; Get Total Generation Rate ;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;; Calculates the current total generation rate across all collections
;; (define-read-only (get-total-generation)
;;   (let
;;     (
;;       (list-of-all-collections-with-active-user-stakes (filter filter-out-collections-with-no-stakes (var-get whitelist-total)))
;;       (list-of-generation-per-collection (map map-from-list-staked-to-generation-per-collection list-of-all-collections-with-active-user-stakes))
;;     )
;;     (ok (fold + list-of-generation-per-collection u0))
;;   )
;; )

;; ;; Filter function used which takes in all (list principal) stakeable/whitelist principals & outputs a (list principal) of actively-staked (by tx-sender) principals
;; (define-private (filter-out-collections-with-no-stakes (collection principal))
;;   (let
;;     (
;;       (collection-staked-by-user-list (default-to (list) (map-get? user-stakes-by-collection {user: tx-sender, collection: collection})))
;;       (collection-staked-by-user-count (len collection-staked-by-user-list))
;;     )
;;     (if (>= collection-staked-by-user-count u0)
;;       true
;;       false
;;     )
;;   )
;; )

;; ;; Map function which takes in a list of actively-staked principals & returns a list of current generation rate per collection
;; (define-private (map-from-list-staked-to-generation-per-collection (collection principal))
;;   (let
;;     (
;;       (this-collection-multiplier (default-to u0 (map-get? collection-multiplier collection)))
;;       (collection-staked-by-user-list (default-to (list) (map-get? user-stakes-by-collection {user: tx-sender, collection: collection})))
;;       (collection-staked-by-user-count (len collection-staked-by-user-list))
;;       (this-collection-multiplier-normalized (/ (* this-collection-multiplier (var-get max-payout-per-block)) u100))
;;     )
;;     (* this-collection-multiplier-normalized collection-staked-by-user-count)
;;   )
;; )

;; ;;;;;;;;

;; ;; Get generation rate for a given collection
;; (define-public (get-generation-by-collection (collection <stake-helper-trait>))
;;   (let
;;     (
;;       (this-collection-multiplier (default-to u0 (map-get? collection-multiplier (contract-of collection))))
;;       (collection-staked-by-user-list (get-staked-by-collection-and-user collection tx-sender))
;;       (collection-staked-by-user-count (len (unwrap! (unwrap! collection-staked-by-user-list (err "err-unwrap")) (err "err-unwrap"))))
;;       (this-collection-multiplier-normalized (/ (* this-collection-multiplier (var-get max-payout-per-block)) u100))
;;     )

;;     ;; check collection is existing whitelist collection
;;     (asserts! (> this-collection-multiplier u0) (err "err-not-whitelisted"))
;;     (ok (* this-collection-multiplier-normalized collection-staked-by-user-count))
;;   )
;; )

;; ;; @desc - Read function that returns a (list uint) of all actively-staked IDs in a collection by tx-sender
;; ;; (define-public (get-staked-by-collection-and-user (collection <stake-helper-trait>) (user principal))
;; ;;   (contract-call? collection get-local-stakes user)
;; ;; )


;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;;;;;; Staking Helper Funcs ;;;;;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; ;; Update Item Staking Data
;; (define-public (create-stake (collection principal) (custodial bool) (item uint))
;;     (let
;;         (
;;             (current-item-staking-data (get-item-staking-data collection item))
;;             (total-whitelisted-collections (var-get whitelist-total))
;;             (custodial-whitelisted-collections (var-get whitelist-custodial))
;;             (noncustodial-whitelisted-collections (var-get whitelist-noncustodial))
;;         )

;;         ;; Assert that the collection is whitelisted
;;         (asserts! (is-some (index-of total-whitelisted-collections collection)) (err "err-collection-not-whitelisted"))

;;         ;; Assert that contract-caller is one of the nft-staking helper contracts
;;         (asserts! (is-some (index-of total-whitelisted-collections contract-caller)) (err "err-not-helper-contract"))

;;         ;; Check if custody-status is correctly set
;;         (if custodial
;;             (asserts! (is-some (index-of custodial-whitelisted-collections collection)) (err "err-collection-custodial-status"))
;;             (asserts! (is-some (index-of noncustodial-whitelisted-collections collection)) (err "err-collection-custodial-status"))
;;         )

;;         (ok (map-set staking-data {collection: collection, item: item} {
;;             staker: (some tx-sender),
;;             last-staked-or-claimed: block-height
;;         }))
;;     )
;; )

;; ;; Claim Staking Rewards
;; ;; @desc - function for staking-helper contracts to call & claim rewards for a given NFT
;; ;; @param - collection:principal - the principal of the collection contract, item:uint - the ID of the NFT
;; (define-public (claim-rewards (collection principal) (item uint)) 
;;   (let
;;     (
;;       (current-item-staking-data (get-item-staking-data collection item))
;;     )
;;     (ok true)
;;   )
;; )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Admin Functions ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; @desc - Function that only an admin user can call to add a new SGC collection for staking
;; @param - Collection (principal or collection?), Collection-Multiple (uint)
;; (define-public (add-whitelisted-collection (collection-helper <stake-helper-trait>) (collection <nft-trait>) (collection-multiple uint) (custodial bool))
;;   (let
;;     (
;;       (active-whitelist-total (var-get whitelisted-collections))
;;       (active-whitelist-custodial (var-get whitelist-custodial))
;;       (active-whitelist-noncustodial (var-get whitelist-noncustodial))
;;       (current-admin-list (var-get team-admins))
;;       (caller-principal-position-in-list (index-of current-admin-list tx-sender))
;;     )

;;     ;;(asserts! (is-some (index-of (var-get whitelist-admins) tx-sender)) (err u40))
;;     (asserts! (is-some caller-principal-position-in-list) (err u200))

;;     ;; assert collection not already added
;;     (asserts! (is-none (index-of active-whitelist-total (contract-of collection))) (err u201))

;;     ;; assert multiple < 100
;;     (asserts! (and (< collection-multiple u101) (> collection-multiple u0)) (err u202))

;;     ;; update collection-multiplier map
;;     (map-set collection-multiplier (contract-of collection) collection-multiple)

;;     (if custodial
;;         ;; Is custodial
;;         (var-set whitelist-custodial (unwrap! (as-max-len? (append active-whitelist-custodial (contract-of collection)) u50) (err u203)) )
;;         ;; Is non-custodial
;;         (var-set whitelist-noncustodial (unwrap! (as-max-len? (append active-whitelist-noncustodial (contract-of collection)) u50) (err u204)) )
;;     )

;;     ;; add new principle to whitelist
;;     (ok (var-set whitelisted-collections (unwrap! (as-max-len? (append active-whitelist-total (contract-of collection)) u100) (err u205)) ))

;;   )
;; )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Add Admin Address For Whitelisting ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @desc - Function for add principals that have explicit permission to add current or future stakeable collections
;; @param - Principal that we're adding as whitelist, initially only admin-one has permission
(define-public (add-team-admin (new-whitelist principal))
  (let
    (
      (current-admin-list (var-get team-admins))
      (caller-principal-position-in-list (index-of current-admin-list tx-sender))
      (param-principal-position-in-list (index-of current-admin-list new-whitelist))
    )

    ;; asserts tx-sender is an existing whitelist address
    (asserts! (is-some caller-principal-position-in-list) (err u100))

    ;; asserts param principal (new whitelist) doesn't already exist
    (asserts! (is-none param-principal-position-in-list) (err u101))

    ;; append new whitelist address
    (ok (var-set team-admins (unwrap! (as-max-len? (append (var-get team-admins) new-whitelist) u10) (err u102))))
  )
)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;; Remove Admin Address For Whitelisting ;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;; @desc - Function for removing principals that have explicit permission to add current or future stakeable collections
;; ;; @param - Principal that we're adding removing as white
;; (define-public (remove-admin-address-for-whitelisting (remove-whitelist principal))
;;   (let
;;     (
;;       (current-admin-list (var-get whitelist-admins))
;;       (caller-principal-position-in-list (index-of current-admin-list tx-sender))
;;       (removeable-principal-position-in-list (index-of current-admin-list remove-whitelist))
;;     )

;;     ;; asserts tx-sender is an existing whitelist address
;;     (asserts! (is-some caller-principal-position-in-list) (err "err-not-admin"))

;;     ;; asserts param principal (removeable whitelist) already exist
;;     (asserts! (is-eq removeable-principal-position-in-list) (err "err-not-whitelisted")) ;;changed error to make sense, changed is-some to is-eq

;;     ;; temporary var set to help remove param principal
;;     (var-set helper-principal remove-whitelist)

;;     ;; need to remove from custodial or noncustodial as well...

;;     ;; filter existing whitelist address
;;     (ok (filter is-not-removeable (var-get whitelist-admins)))
;;   )
;; )

;; ;; @desc - Helper function for removing a specific admin from tne admin whitelist
;; (define-private (is-not-removeable (admin-principal principal))
;;   (not (is-eq admin-principal (var-get helper-principal)))
;; )