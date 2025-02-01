;; WaveNest - Music Discovery Platform Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-invalid-price (err u103))
(define-constant err-invalid-split (err u104))
(define-constant err-playlist-limit (err u105))

;; Data Variables
(define-data-var platform-fee uint u50) ;; 5% fee in basis points

;; Define NFT for Songs
(define-non-fungible-token song uint)

;; Data Maps
(define-map Artists principal
  {
    name: (string-utf8 100),
    bio: (string-utf8 500),
    verified: bool,
    total-songs: uint,
    earnings: uint
  }
)

(define-map Songs uint 
  {
    artist: principal,
    title: (string-utf8 100),
    genre: (string-utf8 50),
    price: uint,
    plays: uint,
    available: bool,
    collaborators: (list 5 {collaborator: principal, share: uint}),
    total-shares: uint
  }
)

(define-map Listeners principal
  {
    preferences: (list 10 (string-utf8 50)),
    played-songs: (list 100 uint),
    rewards: uint,
    playlists: (list 20 {name: (string-utf8 50), songs: (list 100 uint)})
  }
)

;; Counter for Song IDs
(define-data-var song-id-nonce uint u0)

;; Artist Functions
(define-public (register-artist (name (string-utf8 100)) (bio (string-utf8 500)))
  (let ((artist-data (map-get? Artists tx-sender)))
    (asserts! (is-none artist-data) err-already-registered)
    (ok (map-set Artists tx-sender {
      name: name,
      bio: bio,
      verified: false,
      total-songs: u0,
      earnings: u0
    }))
  )
)

;; Song Management with Royalty Splits
(define-public (mint-song (title (string-utf8 100)) (genre (string-utf8 50)) (price uint) (collaborators (list 5 {collaborator: principal, share: uint})))
  (let (
    (artist-data (unwrap! (map-get? Artists tx-sender) err-not-registered))
    (song-id (+ (var-get song-id-nonce) u1))
    (total-shares (fold + (map get-share collaborators) u0))
  )
    (asserts! (> price u0) err-invalid-price)
    (asserts! (<= total-shares u1000) err-invalid-split)
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

;; Playlist Management
(define-public (create-playlist (name (string-utf8 50)))
  (let (
    (listener-data (unwrap! (map-get? Listeners tx-sender) err-not-registered))
    (current-playlists (get playlists listener-data))
  )
    (asserts! (< (len current-playlists) u20) err-playlist-limit)
    (ok (map-set Listeners tx-sender
      (merge listener-data {
        playlists: (append current-playlists [{name: name, songs: (list)}])
      })
    ))
  )
)

(define-public (add-to-playlist (playlist-index uint) (song-id uint))
  (let (
    (listener-data (unwrap! (map-get? Listeners tx-sender) err-not-registered))
    (song-data (unwrap! (map-get? Songs song-id) err-not-registered))
    (current-playlists (get playlists listener-data))
  )
    (ok (map-set Listeners tx-sender
      (merge listener-data {
        playlists: (replace-at current-playlists playlist-index
          {
            name: (get name (unwrap! (element-at current-playlists playlist-index) err-playlist-limit)),
            songs: (append (get songs (unwrap! (element-at current-playlists playlist-index) err-playlist-limit)) song-id)
          }
        )
      })
    ))
  )
)

;; Listener Functions
(define-public (register-listener (preferences (list 10 (string-utf8 50))))
  (let ((listener-data (map-get? Listeners tx-sender)))
    (asserts! (is-none listener-data) err-already-registered)
    (ok (map-set Listeners tx-sender {
      preferences: preferences,
      played-songs: (list),
      rewards: u0,
      playlists: (list)
    }))
  )
)

(define-public (play-song (song-id uint))
  (let (
    (song-data (unwrap! (map-get? Songs song-id) err-not-registered))
    (listener-data (unwrap! (map-get? Listeners tx-sender) err-not-registered))
  )
    (map-set Songs song-id 
      (merge song-data { plays: (+ (get plays song-data) u1) })
    )
    (distribute-royalties song-id)
    (ok true)
  )
)

;; Helper Functions
(define-private (get-share (collab {collaborator: principal, share: uint}))
  (get share collab)
)

(define-private (distribute-royalties (song-id uint))
  (let (
    (song-data (unwrap! (map-get? Songs song-id) err-not-registered))
    (main-artist (get artist song-data))
    (collaborators (get collaborators song-data))
    (total-shares (get total-shares song-data))
  )
    (map-set Artists main-artist
      (merge (unwrap! (map-get? Artists main-artist) err-not-registered)
        { earnings: (+ (get earnings (unwrap! (map-get? Artists main-artist) err-not-registered))
                      (/ (* u1000 (- u1000 total-shares)) u1000)) }
      )
    )
    (map distribute-to-collaborator collaborators)
    (ok true)
  )
)

(define-private (distribute-to-collaborator (collab {collaborator: principal, share: uint}))
  (let (
    (collaborator (get collaborator collab))
    (share (get share collab))
  )
    (map-set Artists collaborator
      (merge (unwrap! (map-get? Artists collaborator) err-not-registered)
        { earnings: (+ (get earnings (unwrap! (map-get? Artists collaborator) err-not-registered))
                      (/ (* u1000 share) u1000)) }
      )
    )
  )
)

;; Read-only Functions
(define-read-only (get-artist-info (artist principal))
  (ok (map-get? Artists artist))
)

(define-read-only (get-song-info (song-id uint))
  (ok (map-get? Songs song-id))
)

(define-read-only (get-listener-info (listener principal))
  (ok (map-get? Listeners listener))
)
