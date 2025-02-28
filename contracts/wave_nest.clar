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
(define-constant max-playlist-songs u100)

;; Data Variables
(define-data-var platform-fee uint u50) ;; 5% fee in basis points

;; [Previous code remains unchanged until mint-song function]

(define-public (mint-song (title (string-utf8 100)) (genre (string-utf8 50)) (price uint) (collaborators (list 5 {collaborator: principal, share: uint})))
  (let (
    (artist-data (unwrap! (map-get? Artists tx-sender) err-not-registered))
    (song-id (+ (var-get song-id-nonce) u1))
    (total-shares (fold + (map get-share collaborators) u0))
    (unique-collaborators (len (fold remove-duplicates collaborators (list))))
  )
    (asserts! (> price u0) err-invalid-price)
    (asserts! (<= total-shares u1000) err-invalid-split)
    (asserts! (is-eq (len collaborators) unique-collaborators) err-duplicate-collaborator)
    (try! (nft-mint? song song-id tx-sender))
    (map-set Songs song-id {
      artist: tx-sender,
      title: title,
      genre: genre,
      price: price,
      plays: u0,
      available: true,
      collaborators: collaborators,
      total-shares: total-shares
    })
    (var-set song-id-nonce song-id)
    (ok song-id)
  )
)

;; [Previous playlist management code remains unchanged]

(define-public (add-to-playlist (playlist-index uint) (song-id uint))
  (let (
    (listener-data (unwrap! (map-get? Listeners tx-sender) err-not-registered))
    (song-data (unwrap! (map-get? Songs song-id) err-not-registered))
    (current-playlists (get playlists listener-data))
    (current-playlist (unwrap! (element-at current-playlists playlist-index) err-playlist-limit))
    (current-songs (get songs current-playlist))
  )
    (asserts! (< (len current-songs) max-playlist-songs) err-playlist-limit)
    (ok (map-set Listeners tx-sender
      (merge listener-data {
        playlists: (replace-at current-playlists playlist-index
          {
            name: (get name current-playlist),
            songs: (append current-songs song-id)
          }
        )
      })
    ))
  )
)

;; Helper Functions
(define-private (remove-duplicates (collab {collaborator: principal, share: uint}) (acc (list 5 principal)))
  (if (is-some (index-of acc (get collaborator collab)))
    acc
    (append acc (get collaborator collab))
  )
)

;; [Remaining code unchanged]
