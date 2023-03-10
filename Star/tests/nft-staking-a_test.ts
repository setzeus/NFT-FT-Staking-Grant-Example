
import { Clarinet, Tx, Chain, Account, Contract, types } from 'https://deno.land/x/clarinet@v0.31.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// Mint & stake 1 NFT-A (custodial)
Clarinet.test({
    name: "Can mint & stake (custodial) 1 NFT-A",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;

        let startBlock = chain.mineBlock([
            Tx.contractCall("staking", "add-whitelisted-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-staking-a')], deployer.address),
            Tx.contractCall("nft-a", "mint-nft-a", [], deployer.address)
        ]);
        //console.log(chain.getAssetsMaps())

        chain.mineEmptyBlock(1);

        let stakeBlock = chain.mineBlock([
            Tx.contractCall("nft-staking-a", "stake-item", [types.uint(1)], deployer.address),
        ]);

        //console.log(chain.getAssetsMaps())
        //console.log(stakeBlock.receipts[0].result)

        stakeBlock.receipts[0].result.expectOk().expectBool(true);
    },
})

// Update multiplier for collection
Clarinet.test({
    name: "Can update multiplier for collection",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;

        const callBefore = chain.callReadOnlyFn("nft-staking-a", "get-multiplier", [], deployer.address);
        console.log(callBefore);

        let updateBlock = chain.mineBlock([
            Tx.contractCall("staking", "add-whitelisted-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-staking-a')], deployer.address),
            Tx.contractCall("nft-a", "mint-nft-a", [], deployer.address)
        ]);

        const callAfter = chain.callReadOnlyFn("nft-staking-a", "get-multiplier", [], deployer.address);
        console.log(callAfter);

        console.log(chain.getAssetsMaps())
        console.log(updateBlock.receipts[0].result)

        updateBlock.receipts[0].result.expectOk().expectBool(true);
    },
})



// ;; Claim item balance
// (claim-item (uint) (response bool uint))

// ;; Unstake item
// (unstake-item (uint) (response bool uint))