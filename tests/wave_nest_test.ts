Clarinet.test({
  name: "Comprehensive collaborator validation test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const artist = accounts.get('wallet_1')!;
    const collaborator1 = accounts.get('wallet_2')!;
    const collaborator2 = accounts.get('wallet_3')!;
    
    // Register artists
    chain.mineBlock([
      Tx.contractCall('wave-nest', 'register-artist', [
        types.utf8("Test Artist"),
        types.utf8("Test Bio")
      ], artist.address),
      Tx.contractCall('wave-nest', 'register-artist', [
        types.utf8("Collaborator 1"),
        types.utf8("Collab Bio")
      ], collaborator1.address)
    ]);
    
    // Test duplicate collaborators
    let block = chain.mineBlock([
      Tx.contractCall('wave-nest', 'mint-song', [
        types.utf8("Test Song"),
        types.utf8("Pop"),
        types.uint(1000000),
        types.list([
          {
            collaborator: types.principal(collaborator1.address),
            share: types.uint(500)
          },
          {
            collaborator: types.principal(collaborator1.address),
            share: types.uint(500)
          }
        ])
      ], artist.address)
    ]);
    block.receipts[0].result.expectErr(106);
    
    // Test invalid total shares
    block = chain.mineBlock([
      Tx.contractCall('wave-nest', 'mint-song', [
        types.utf8("Test Song"),
        types.utf8("Pop"),
        types.uint(1000000),
        types.list([
          {
            collaborator: types.principal(collaborator1.address),
            share: types.uint(400)
          },
          {
            collaborator: types.principal(collaborator2.address),
            share: types.uint(400)
          }
        ])
      ], artist.address)
    ]);
    block.receipts[0].result.expectErr(104);
    
    // Test empty collaborator list
    block = chain.mineBlock([
      Tx.contractCall('wave-nest', 'mint-song', [
        types.utf8("Test Song"),
        types.utf8("Pop"),
        types.uint(1000000),
        types.list([])
      ], artist.address)
    ]);
    block.receipts[0].result.expectErr(107);
  },
});
