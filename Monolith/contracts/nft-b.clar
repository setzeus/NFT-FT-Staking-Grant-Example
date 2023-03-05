;; NFT - B
;; Stacks Grant example contract for NFT(s) -> FT Staking SIP
;; NFT A is the main/primary collection for a team
;; Written by Setzeus/StrataLabs

(impl-trait .sip-09.nft-trait)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Cons, Vars, & Maps ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;
;; NFT Vars/Cons ;;
;;;;;;;;;;;;;;;;;;;

;;define nft-b nft
(define-non-fungible-token nft-b uint)

;; nft-b(s) NFT collection limit (1000)
(define-constant nft-b-limit u1000)

;; String that represents the current ipfs-root
(define-constant ipfs-root "ipfs://ipfs//")

;; Uint that represents the current nft-b that'll be minted
(define-data-var nft-b-index uint u1)

;; Map that keeps track of listing by nft-b ID/uint
(define-map market uint
  {
    price: uint,
    commission: principal
  }
)

;;;;;;;;;;;;;;;;
;; Error Cons ;;
;;;;;;;;;;;;;;;;

(define-constant ERR-ALL-MINTED (err u101))
(define-constant ERR-NOT-AUTH (err u102))
(define-constant ERR-NOT-LISTED (err u103))
(define-constant ERR-WRONG-COMMISSION (err u104))
(define-constant ERR-NOT-OWNER (err u106))
(define-constant ERR-INCORRECT-SUBTYPES (err u107))
(define-constant ERR-nft-b-NOT-OWNER (err u108))
(define-constant ERR-CURRENTLY-STAKED (err u109))
(define-constant ERR-UNWRAP-STAKE-STATUS (err u110))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; SIP09 Functions ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-read-only (get-last-token-id)
  (ok (var-get nft-b-index))
)

(define-read-only (get-owner (id uint))
  (ok (nft-get-owner? nft-b id))
)

(define-read-only (get-token-uri (token-id uint))
  (ok
    (some
      (concat
        (concat
          ipfs-root
          (uint-to-ascii token-id)
        )
        ".json"
      )
    )
  )
)

(define-public (transfer (id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-AUTH)
    ;; asserts not actively staked
    (asserts! (not (is-eq (get staker (unwrap! (contract-call? .staking get-stake-details (as-contract tx-sender) id) ERR-UNWRAP-STAKE-STATUS)) tx-sender)) ERR-CURRENTLY-STAKED)
    (nft-transfer? nft-b id sender recipient)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Non-Custodial Functions ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-trait commission-trait .commission-trait.commission)

;; @desc gets market listing by market list ID
;; @param id; the ID of the market listing
(define-read-only (get-listing-in-ustx (id uint))
  (map-get? market id)
)

;; @desc checks NFT owner is either tx-sender or contract caller,
;; @param id; the ID of the NFT in question
(define-private (is-sender-owner (id uint))
  (let
    (
      (owner (unwrap! (nft-get-owner? nft-b id) false))
    )
      (or (is-eq tx-sender owner) (is-eq contract-caller owner))
  )
)

;; @desc listing function
;; @param id: the ID of the NFT in question, price: the price being listed, comm-trait: a principal that conforms to the commission-trait
(define-public (list-in-ustx (id uint) (price uint) (comm-trait <commission-trait>))
  (let
    (
      (listing {price: price, commission: (contract-of comm-trait)})
    )

    ;; asserts not actively staked
    (asserts! (not (is-eq (get staker (unwrap! (contract-call? .staking get-stake-details (as-contract tx-sender) id) ERR-UNWRAP-STAKE-STATUS)) tx-sender)) ERR-CURRENTLY-STAKED)

    (asserts! (is-sender-owner id) ERR-NOT-AUTH)
    (map-set market id listing)
    (ok (print (merge listing {a: "list-in-ustx", id: id})))
  )
)

;; @desc un-listing function
;; @param id: the ID of the NFT in question, price: the price being listed, comm-trait: a principal that conforms to the commission-trait
(define-public (unlist-in-ustx (id uint))
  (begin
    (asserts! (is-sender-owner id) ERR-NOT-AUTH)
    (map-delete market id)
    (ok (print {a: "unlist-in-stx", id: id}))
  )
)

;; @desc function to buy from a current listing
;; @param buy: the ID of the NFT in question, comm-trait: a principal that conforms to the commission-trait for royalty split
(define-public (buy-in-ustx (id uint) (comm-trait <commission-trait>))
  (let
    (
      (owner (unwrap! (nft-get-owner? nft-b id) ERR-NOT-AUTH))
      (listing (unwrap! (map-get? market id) ERR-NOT-LISTED))
      (price (get price listing))
    )
    (asserts! (is-eq (contract-of comm-trait) (get commission listing)) ERR-WRONG-COMMISSION)
    (try! (stx-transfer? price tx-sender owner))
    (try! (contract-call? comm-trait pay id price))
    (try! (transfer id owner tx-sender))
    (map-delete market id)
    (ok (print {a: "buy-in-ustx", id: id}))
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Read Functions ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Mint Functions ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; @desc nft-b mint function
;; @param none
(define-public (mint-nft-b)
  (let
    (
      (current-id (var-get nft-b-index))
      (next-id (+ current-id u1))
    )

    ;; assert that nft-b-index < nft-b-collection limit
    (asserts! (< current-id nft-b-limit) ERR-ALL-MINTED)

    ;; mint nft-b to tx-sender
    (try! (nft-mint? nft-b current-id tx-sender))

    ;; updated index
    (ok (var-set nft-b-index next-id))
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Help Functions ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; @desc utility function that takes in a unit & returns a string
;; @param value; the unit we're casting into a string to concatenate
;; thanks to Lnow for the guidance
(define-read-only (uint-to-ascii (value uint))
  (if (<= value u9)
    (unwrap-panic (element-at "0123456789" value))
    (get r (fold uint-to-ascii-inner
      0x000000000000000000000000000000000000000000000000000000000000000000000000000000
      {v: value, r: ""}
    ))
  )
)

(define-read-only (uint-to-ascii-inner (i (buff 1)) (d {v: uint, r: (string-ascii 39)}))
  (if (> (get v d) u0)
    {
      v: (/ (get v d) u10),
      r: (unwrap-panic (as-max-len? (concat (unwrap-panic (element-at "0123456789" (mod (get v d) u10))) (get r d)) u39))
    }
    d
  )
)