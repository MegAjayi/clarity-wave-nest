;; WaveNest - Music Discovery Platform Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-invalid-price (err u103))
(define-constant err-invalid-split (err u104))
(define-constant err-playlist-limit (err u105))
(define-constant err-duplicate-collaborator (err u106))
(define-constant err-empty-collaborators (err u107))
(define-constant max-playlist-songs u100)
(define-constant basis-points u1000)

;; Data Variables
(define-data-var platform-fee uint u50) ;; 5% fee in basis points

;; Helper Functions
(define-private (validate-collaborators (collaborators (list 5 {collaborator: principal, share: uint})))
  (let (
    (total-shares (fold + (map get-share collaborators) u0))
    (unique-collabs (len (fold check-duplicate collaborators {count: u0, seen: (list 5 principal)})))
  )
    (and
      (is-eq (len collaborators) unique-collabs)
      (is-eq total-shares basis-points)
      (> (len collaborators) u0)
    )
  )
)

(define-private (check-duplicate (collab {collaborator: principal, share: uint}) 
  (acc {count: uint, seen: (list 5 principal)}))
  (let ((seen (get seen acc)))
    (if (is-some (index-of seen (get collaborator collab)))
      acc
      {
        count: (+ (get count acc) u1),
        seen: (append seen (get collaborator collab))
      }
    )
  )
)

(define-public (mint-song (title (string-utf8 100)) (genre (string-utf8 50)) 
  (price uint) (collaborators (list 5 {collaborator: principal, share: uint})))
  (let (
    (artist-data (unwrap! (map-get? Artists tx-sender) err-not-registered))
    (song-id (+ (var-get song-id-nonce) u1))
  )
    (asserts! (> price u0) err-invalid-price)
    (asserts! (> (len collaborators) u0) err-empty-collaborators)
    (asserts! (validate-collaborators collaborators) err-invalid-split)
    
    (try! (nft-mint? song song-id tx-sender))
    (map-set Songs song-id {
      artist: tx-sender,
      title: title,
      genre: genre,
      price: price,
      plays: u0,
      available: true,
      collaborators: collaborators,
      total-shares: basis-points
    })
    (var-set song-id-nonce song-id)
    (ok song-id)
  )
)

;; [Previous playlist management code remains unchanged]
