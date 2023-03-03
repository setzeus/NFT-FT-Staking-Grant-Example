
import { Clarinet, Tx, Chain, Account, Contract, types } from 'https://deno.land/x/clarinet@v0.31.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const stakingContract = "staking";

const defaultNFTContract = "sip-09";
const defaultFTContract = "sip-10";
const nftAContract = "nft-a";

const stakingPrincipal = (deployer: Account) => '${deployer.address}.${stakingContract}';
const nftAPrincipal = (deployer: Account) => '${deployer.address}.${nftAContract}';

// Admin add NFT-A for staking
Clarinet.test({
    name: "Admin can add a new collection to the appropriate lists (custodial)",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1), types.bool(true)], deployer.address)
        ]);

        block.receipts[0].result.expectOk().expectBool(true);
    },
})

// Mint 1 NFT-A
Clarinet.test({
    name: "Can mint 1 NFT-A",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;

        let startBlock = chain.mineBlock([
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1), types.bool(true)], deployer.address),
            Tx.contractCall("nft-a", "mint-nft-a", [], deployer.address)
        ]);

        startBlock.receipts[0].result.expectOk().expectBool(true);
    },
})

// Mint & stake 1 NFT-A
Clarinet.test({
    name: "Can mint & stake 1 NFT-A",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;

        let startBlock = chain.mineBlock([
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1), types.bool(true)], deployer.address),
            Tx.contractCall("nft-a", "mint-nft-a", [], deployer.address)
        ]);

        chain.mineEmptyBlock(1);

        let stakeBlock = chain.mineBlock([
            Tx.contractCall("staking", "stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
        ]);

       //chain.mineEmptyBlock(1);

        //let claimBlock = chain.mineBlock([]);

        console.log(stakeBlock.receipts[0].events)
        console.log(stakeBlock.receipts[0].result)

        stakeBlock.receipts[0].result.expectOk().expectBool(true);
    },
})

// Mint, stake & claim 1 NFT-A
Clarinet.test({
    name: "Can mint, stake & claim 1 NFT-A for 10000 FT",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;

        let startBlock = chain.mineBlock([
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1), types.bool(true)], deployer.address),
            Tx.contractCall("nft-a", "mint-nft-a", [], deployer.address)
        ]);

        chain.mineEmptyBlock(1);

        let stakeBlock = chain.mineBlock([
            Tx.contractCall("staking", "stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
        ]);

        //chain.mineEmptyBlock(1);

        let claimBlock = chain.mineBlock([
            Tx.contractCall("staking", "claim-item-stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
        ]);

        console.log(chain.getAssetsMaps())
        console.log(claimBlock.receipts[0].result)

        assertEquals(chain.getAssetsMaps().assets['.ft.example-ft'][deployer.address], 10000)
        claimBlock.receipts[0].result.expectOk().expectBool(true);
    },
})

// Mint, stake, claim & unclaim 1 NFT-A
Clarinet.test({
    name: "Can mint, stake, claim unstake 1 NFT-A for 10000 FT",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;

        let startBlock = chain.mineBlock([
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1), types.bool(true)], deployer.address),
            Tx.contractCall("nft-a", "mint-nft-a", [], deployer.address)
        ]);

        chain.mineEmptyBlock(1);

        let stakeBlock = chain.mineBlock([
            Tx.contractCall("staking", "stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
        ]);

        //chain.mineEmptyBlock(1);

        let claimUnstakeBlock = chain.mineBlock([
            Tx.contractCall("staking", "claim-item-stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
            Tx.contractCall("staking", "unstake-item", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
        ]);

        console.log(chain.getAssetsMaps())
        console.log(claimUnstakeBlock.receipts[0].result)

        assertEquals(chain.getAssetsMaps().assets['.ft.example-ft'][deployer.address], 10000)
        assertEquals(chain.getAssetsMaps().assets['.nft-a.nft-a'][deployer.address], 1)
        claimUnstakeBlock.receipts[0].result.expectOk().expectBool(true);
    },
})