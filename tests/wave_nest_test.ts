import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Artist registration test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const artist = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('wave-nest', 'register-artist', [
        types.utf8("Test Artist"),
        types.utf8("Test Bio")
      ], artist.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify artist info
    let getArtist = chain.mineBlock([
      Tx.contractCall('wave-nest', 'get-artist-info', [
        types.principal(artist.address)
      ], deployer.address)
    ]);
    
    const artistData = getArtist.receipts[0].result.expectOk().expectSome();
    assertEquals(artistData['name'], "Test Artist");
  },
});

Clarinet.test({
  name: "Song minting with collaborators test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const artist = accounts.get('wallet_1')!;
    const collaborator = accounts.get('wallet_2')!;
    
    // Register artist and collaborator
    chain.mineBlock([
      Tx.contractCall('wave-nest', 'register-artist', [
        types.utf8("Test Artist"),
        types.utf8("Test Bio")
      ], artist.address),
      Tx.contractCall('wave-nest', 'register-artist', [
        types.utf8("Collaborator"),
        types.utf8("Collab Bio")
      ], collaborator.address)
    ]);
    
    // Mint song with collaborator
    let block = chain.mineBlock([
      Tx.contractCall('wave-nest', 'mint-song', [
        types.utf8("Test Song"),
        types.utf8("Pop"),
        types.uint(1000000),
        types.list([
          {
            collaborator: types.principal(collaborator.address),
            share: types.uint(200) // 20% share
          }
        ])
      ], artist.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify song info
    let getSong = chain.mineBlock([
      Tx.contractCall('wave-nest', 'get-song-info', [
        types.uint(1)
      ], artist.address)
    ]);
    
    const songData = getSong.receipts[0].result.expectOk().expectSome();
    assertEquals(songData['title'], "Test Song");
    assertEquals(songData['total-shares'], types.uint(200));
  },
});

Clarinet.test({
  name: "Playlist creation and management test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const listener = accounts.get('wallet_3')!;
    const artist = accounts.get('wallet_1')!;
    
    // Register listener
    chain.mineBlock([
      Tx.contractCall('wave-nest', 'register-listener', [
        types.list([types.utf8("Pop"), types.utf8("Rock")])
      ], listener.address)
    ]);
    
    // Create playlist
    let createPlaylist = chain.mineBlock([
      Tx.contractCall('wave-nest', 'create-playlist', [
        types.utf8("My Playlist")
      ], listener.address)
    ]);
    
    createPlaylist.receipts[0].result.expectOk();
    
    // Register artist and mint song
    chain.mineBlock([
      Tx.contractCall('wave-nest', 'register-artist', [
        types.utf8("Test Artist"),
        types.utf8("Test Bio")
      ], artist.address)
    ]);
    
    chain.mineBlock([
      Tx.contractCall('wave-nest', 'mint-song', [
        types.utf8("Test Song"),
        types.utf8("Pop"),
        types.uint(1000000),
        types.list([])
      ], artist.address)
    ]);
    
    // Add song to playlist
    let addToPlaylist = chain.mineBlock([
      Tx.contractCall('wave-nest', 'add-to-playlist', [
        types.uint(0),
        types.uint(1)
      ], listener.address)
    ]);
    
    addToPlaylist.receipts[0].result.expectOk();
    
    // Verify playlist
    let getListener = chain.mineBlock([
      Tx.contractCall('wave-nest', 'get-listener-info', [
        types.principal(listener.address)
      ], listener.address)
    ]);
    
    const listenerData = getListener.receipts[0].result.expectOk().expectSome();
    assertEquals(listenerData['playlists'].length, 1);
  },
});
