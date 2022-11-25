;; Staking (star)
;; Stacks Grant example contract for NFT(s) -> FT Staking SIP
;; This contract is in charge of most, but not all staking operations as decentralizes the monolith staking example
;; Written by Setzeus/StrataLabs

(use-trait nft-trait .sip-09.nft-trait)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Cons, Vars, & Maps ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; List of all whitelisted collections
(define-data-var whitelist-total (list 100 principal) (list ))

;; List of custodial collections
(define-data-var whitelist-custodial (list 50 principal) (list ))

;; List of non-custodial collections
(define-data-var whitelist-noncustodial (list 50 principal) (list ))

;; List of principals that are whitelisted/have admin privileges
(define-data-var whitelist-admins (list 10 principal) (list tx-sender))

;; @desc - Uint that represents that *max* possible stake reward per block (a multiplier of u100)
(define-data-var max-payout-per-block uint u1000000)

;; @desc - Map that keeps track of whitelisted principal (key) & corresponding multiplier (value)
(define-map collection-multiplier principal uint)

;; Var for helping principals with list
(define-data-var helper-principal principal tx-sender)

;; Map that defines the staking status for an NFT
(define-map staking-data {collection: principal, item: uint} {
    staker: (optional principal),
    last-staked-or-claimed: uint
})

;; Map that tracks all staked IDs in a collection (value) by user & collection & ID (key)
(define-map user-stakes-by-collection {user: principal, collection: principal}
  (list 10000 uint)
)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Read Functions ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Get Active Collections
(define-read-only (get-active-collections)
    (var-get whitelist-total)
)

;; Get Item Staking Data
(define-read-only (get-item-staking-data (collection principal) (item uint)) 
    (map-get? staking-data {collection: collection, item: item})
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Get Total Generation Rate ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculates the current total generation rate across all collections
(define-read-only (get-total-generation)
  (let
    (
      (list-of-all-collections-with-active-user-stakes (filter filter-out-collections-with-no-stakes (var-get whitelist-total)))
      (list-of-generation-per-collection (map map-from-list-staked-to-generation-per-collection list-of-all-collections-with-active-user-stakes))
    )
    (ok (fold + list-of-generation-per-collection u0))
  )
)

;; Filter function used which takes in all (list principal) stakeable/whitelist principals & outputs a (list principal) of actively-staked (by tx-sender) principals
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

;; Map function which takes in a list of actively-staked principals & returns a list of current generation rate per collection
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

;;;;;;;;

;; Get generation rate for a given collection
(define-read-only (get-generation-by-collection (collection principal))
  (let
    (
      (this-collection-multiplier (default-to u0 (map-get? collection-multiplier collection)))
      (collection-staked-by-user-list (get-staked-by-collection-and-user collection))
      (collection-staked-by-user-count (len (unwrap! collection-staked-by-user-list (err "err-unwrap"))))
      (this-collection-multiplier-normalized (/ (* this-collection-multiplier (var-get max-payout-per-block)) u100))
    )

    ;; check collection is existing whitelist collection
    (asserts! (> this-collection-multiplier u0) (err "err-not-whitelisted"))
    (ok (* this-collection-multiplier-normalized collection-staked-by-user-count))
  )
)

;; @desc - Read function that returns a (list uint) of all actively-staked IDs in a collection by tx-sender
(define-read-only (get-staked-by-collection-and-user (collection principal))
  (ok (default-to (list) (map-get? user-stakes-by-collection {user: tx-sender, collection: collection})))
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Staking Helper Funcs ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Update Item Staking Data
(define-public (create-stake (collection principal) (custodial bool) (item uint))
    (let
        (
            (current-item-staking-data (get-item-staking-data collection item))
            (total-white-listed-collections (var-get whitelist-total))
            (custodial-white-listed-collections (var-get whitelist-custodial))
            (noncustodial-white-listed-collections (var-get whitelist-noncustodial))
        )

        ;; Assert that the collection is whitelisted
        (asserts! (is-some (index-of total-white-listed-collections collection)) (err "err-collection-not-whitelisted"))

        ;; Check if custody-status is correctly set
        (if custodial
            (asserts! (is-some (index-of custodial-white-listed-collections collection)) (err "err-collection-custodial-status"))
            (asserts! (is-some (index-of noncustodial-white-listed-collections collection)) (err "err-collection-custodial-status"))
        )

        (ok (map-set staking-data {collection: collection, item: item} {
            staker: (some tx-sender),
            last-staked-or-claimed: block-height
        }))
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Admin Functions ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; @desc - Function that only an admin user can call to add a new SGC collection for staking
;; @param - Collection (principal or collection?), Collection-Multiple (uint)
(define-public (admin-add-new-collection (collection principal) (custodial bool) (collection-multiple uint) (custodial bool))
  (let
    (
      (active-whitelist-total (var-get whitelist-total))
      (active-whitelist-custodial (var-get whitelist-custodial))
      (active-whitelist-noncustodial (var-get whitelist-noncustodial))
      (current-admin-list (var-get whitelist-admins))
      (caller-principal-position-in-list (index-of current-admin-list tx-sender))
    )

    ;;(asserts! (is-some (index-of (var-get whitelist-admins) tx-sender)) (err u40))
    (asserts! (is-some caller-principal-position-in-list) (err "err-not-admin"))

    ;; assert collection not already added
    (asserts! (is-none (index-of active-whitelist-total collection)) (err "err-collection-already-added"))

    ;; assert multiple < 100
    (asserts! (and (< collection-multiple u101) (> collection-multiple u0)) (err "err-collection-multiple"))

    ;; update collection-multiplier map
    (map-set collection-multiplier collection collection-multiple)

    (if custodial
        ;; Is custodial
        (var-set whitelist-custodial (unwrap! (as-max-len? (append active-whitelist-custodial collection) u50) (err "err-custodial-whitelist-overflow")) )
        ;; Is non-custodial
        (var-set whitelist-noncustodial (unwrap! (as-max-len? (append active-whitelist-noncustodial collection) u50) (err "err-custodial-whitelist-overflow")) )
    )

    ;; add new principle to whitelist
    (ok (var-set whitelist-total (unwrap! (as-max-len? (append active-whitelist-total collection) u100) (err "err-total-whitelist-overflow")) ))

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
      (current-admin-list (var-get whitelist-admins))
      (caller-principal-position-in-list (index-of current-admin-list tx-sender))
      (param-principal-position-in-list (index-of current-admin-list new-whitelist))
    )

    ;; asserts tx-sender is an existing whitelist address
    (asserts! (is-some caller-principal-position-in-list) (err "err-not-admin"))

    ;; asserts param principal (new whitelist) doesn't already exist
    (asserts! (is-none param-principal-position-in-list) (err "err-admin-already-exists"))

    ;; append new whitelist address
    (ok (var-set whitelist-admins (unwrap! (as-max-len? (append (var-get whitelist-admins) new-whitelist) u10) (err "err-admin-overflow"))))
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
      (current-admin-list (var-get whitelist-admins))
      (caller-principal-position-in-list (index-of current-admin-list tx-sender))
      (removeable-principal-position-in-list (index-of current-admin-list remove-whitelist))
    )

    ;; asserts tx-sender is an existing whitelist address
    (asserts! (is-some caller-principal-position-in-list) (err "err-not-admin"))

    ;; asserts param principal (removeable whitelist) already exist
    (asserts! (is-eq removeable-principal-position-in-list) (err "err-not-whitelisted")) ;;changed error to make sense, changed is-some to is-eq

    ;; temporary var set to help remove param principal
    (var-set helper-principal remove-whitelist)

    ;; need to remove from custodial or noncustodial as well...

    ;; filter existing whitelist address
    (ok (filter is-not-removeable (var-get whitelist-admins)))
  )
)

;; @desc - Helper function for removing a specific admin from tne admin whitelist
(define-private (is-not-removeable (admin-principal principal))
  (not (is-eq admin-principal (var-get helper-principal)))
)