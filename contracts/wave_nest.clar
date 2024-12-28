;; WaveNest - Music Discovery Platform Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-invalid-price (err u103))

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
    available: bool
  }
)

(define-map Listeners principal
  {
    preferences: (list 10 (string-utf8 50)),
    played-songs: (list 100 uint),
    rewards: uint
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

;; Song Management
(define-public (mint-song (title (string-utf8 100)) (genre (string-utf8 50)) (price uint))
  (let (
    (artist-data (unwrap! (map-get? Artists tx-sender) err-not-registered))
    (song-id (+ (var-get song-id-nonce) u1))
  )
    (asserts! (> price u0) err-invalid-price)
    (try! (nft-mint? song song-id tx-sender))
    (map-set Songs song-id {
      artist: tx-sender,
      title: title,
      genre: genre,
      price: price,
      plays: u0,
      available: true
    })
    (var-set song-id-nonce song-id)
    (ok song-id)
  )
)

;; Listener Functions
(define-public (register-listener (preferences (list 10 (string-utf8 50))))
  (let ((listener-data (map-get? Listeners tx-sender)))
    (asserts! (is-none listener-data) err-already-registered)
    (ok (map-set Listeners tx-sender {
      preferences: preferences,
      played-songs: (list),
      rewards: u0
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
    (ok true)
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