// [Previous imports and first two tests remain unchanged]

Clarinet.test({
  name: "Duplicate collaborator validation test",
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
    
    // Attempt to mint song with duplicate collaborator
    let block = chain.mineBlock([
      Tx.contractCall('wave-nest', 'mint-song', [
        types.utf8("Test Song"),
        types.utf8("Pop"),
        types.uint(1000000),
        types.list([
          {
            collaborator: types.principal(collaborator.address),
            share: types.uint(200)
          },
          {
            collaborator: types.principal(collaborator.address),
            share: types.uint(200)
          }
        ])
      ], artist.address)
    ]);
    
    block.receipts[0].result.expectErr(106); // err-duplicate-collaborator
  },
});

// [Remaining tests unchanged]
