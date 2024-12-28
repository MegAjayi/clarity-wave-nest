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
  name: "Song minting test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const artist = accounts.get('wallet_1')!;
    
    // Register artist first
    let register = chain.mineBlock([
      Tx.contractCall('wave-nest', 'register-artist', [
        types.utf8("Test Artist"),
        types.utf8("Test Bio")
      ], artist.address)
    ]);
    
    // Mint song
    let block = chain.mineBlock([
      Tx.contractCall('wave-nest', 'mint-song', [
        types.utf8("Test Song"),
        types.utf8("Pop"),
        types.uint(1000000)
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
    assertEquals(songData['genre'], "Pop");
  },
});

Clarinet.test({
  name: "Listener registration and song play test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const listener = accounts.get('wallet_2')!;
    
    // Register listener
    let register = chain.mineBlock([
      Tx.contractCall('wave-nest', 'register-listener', [
        types.list([types.utf8("Pop"), types.utf8("Rock")])
      ], listener.address)
    ]);
    
    register.receipts[0].result.expectOk();
    
    // Verify listener info
    let getListener = chain.mineBlock([
      Tx.contractCall('wave-nest', 'get-listener-info', [
        types.principal(listener.address)
      ], listener.address)
    ]);
    
    const listenerData = getListener.receipts[0].result.expectOk().expectSome();
    assertEquals(listenerData['rewards'], types.uint(0));
  },
});