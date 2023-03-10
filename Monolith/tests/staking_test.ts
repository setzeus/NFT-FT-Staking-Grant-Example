
import { Clarinet, Tx, Chain, Account, Contract, types } from 'https://deno.land/x/clarinet@v0.31.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const stakingContract = "staking";
const defaultNFTContract = "sip-09";
const defaultFTContract = "sip-10";
const nftAContract = "nft-a";

const stakingPrincipal = (deployer: Account) => '${deployer.address}.${stakingContract}';
const nftAPrincipal = (deployer: Account) => '${deployer.address}.${nftAContract}';

// Admin add NFT-A (custodial) for staking
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

// Admin add both NFT-A (custodial) & NFT-B (non-custodial) for staking
Clarinet.test({
    name: "Admin can add two new collections to the appropriate lists (custodial)",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1), types.bool(true)], deployer.address),
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-b'), types.uint(1), types.bool(true)], deployer.address)
        ]);

        block.receipts[0].result.expectOk().expectBool(true);
    },
})

// Mint 1 NFT-A (custodial)
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

// Mint 1 NFT-A (custodial) & 1 NFT-B (non-custodial)
Clarinet.test({
    name: "Can mint 1 NFT-A & 1 NFT-B",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;

        let startBlock = chain.mineBlock([
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1), types.bool(true)], deployer.address),
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-b'), types.uint(1), types.bool(true)], deployer.address),
            Tx.contractCall("nft-a", "mint-nft-a", [], deployer.address),
            Tx.contractCall("nft-b", "mint-nft-b", [], deployer.address)
        ]);

        //console.log(startBlock.receipts[0].result)
        //console.log(startBlock.receipts[1].result)
        //console.log(startBlock.receipts[2].result)
        //console.log(startBlock.receipts[3].result)
        //console.log(chain.getAssetsMaps())
        assertEquals(chain.getAssetsMaps().assets['.nft-a.nft-a'][deployer.address], 1)
        assertEquals(chain.getAssetsMaps().assets['.nft-b.nft-b'][deployer.address], 1)
        //startBlock.receipts[0].result.expectOk().expectBool(true);
    },
})

// Mint & stake 1 NFT-A (custodial)
Clarinet.test({
    name: "Can mint & stake (custodial) 1 NFT-A",
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

        //console.log(stakeBlock.receipts[0].events)
        //console.log(stakeBlock.receipts[0].result)

        stakeBlock.receipts[0].result.expectOk().expectBool(true);
    },
})

// Mint & stake 1 NFT-A (custodial) & 1 NFT-B (non-custodial)
Clarinet.test({
    name: "Can mint & stake 1 NFT-A & 1 NFT-B",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;

        let startBlock = chain.mineBlock([
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1), types.bool(true)], deployer.address),
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-b'), types.uint(1), types.bool(false)], deployer.address),
            Tx.contractCall("nft-a", "mint-nft-a", [], deployer.address),
            Tx.contractCall("nft-b", "mint-nft-b", [], deployer.address)
        ]);

        chain.mineEmptyBlock(1);
        
        let stakeBlock = chain.mineBlock([
            Tx.contractCall("staking", "stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
            Tx.contractCall("staking", "stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-b'), types.uint(1)], deployer.address),
        ]);

        //console.log(stakeBlock.receipts[0].events)
        //console.log(stakeBlock.receipts[0].result)
        //console.log(stakeBlock.receipts[1].events)
        //console.log(stakeBlock.receipts[1].result)
        //console.log(chain.getAssetsMaps())
        assertEquals(chain.getAssetsMaps().assets['.nft-a.nft-a'][deployer.address], 0)
        assertEquals(chain.getAssetsMaps().assets['.nft-b.nft-b'][deployer.address], 1)
        stakeBlock.receipts[0].result.expectOk().expectBool(true);
        stakeBlock.receipts[1].result.expectOk().expectBool(true);
    },
})

// Mint, stake & claim 1 NFT-A (custodial)
Clarinet.test({
    name: "Can mint, stake (custodial) & claim 1 NFT-A for 10000 FT",
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

        //console.log(chain.getAssetsMaps())
        //console.log(claimBlock.receipts[0].result)

        assertEquals(chain.getAssetsMaps().assets['.ft.example-ft'][deployer.address], 10000)
        claimBlock.receipts[0].result.expectOk().expectBool(true);
    },
})

// Mint, stake & claim 1 NFT-A (custodial) & 1 NFT-B (non-custodial)
Clarinet.test({
    name: "Can mint, stake, & claim 1 NFT-A & 1 NFT-B",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;

        let startBlock = chain.mineBlock([
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1), types.bool(true)], deployer.address),
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-b'), types.uint(1), types.bool(false)], deployer.address),
            Tx.contractCall("nft-a", "mint-nft-a", [], deployer.address),
            Tx.contractCall("nft-b", "mint-nft-b", [], deployer.address)
        ]);

        chain.mineEmptyBlock(1);

        //console.log(chain.getAssetsMaps())

        let stakeBlock = chain.mineBlock([
            Tx.contractCall("staking", "stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
            Tx.contractCall("staking", "stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-b'), types.uint(1)], deployer.address),
        ]);

        chain.mineEmptyBlock(1);

        let claimBlock = chain.mineBlock([
            //Tx.contractCall("staking", "stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
            //Tx.contractCall("staking", "stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-b'), types.uint(1)], deployer.address),
            Tx.contractCall("staking", "claim-item-stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
            Tx.contractCall("staking", "claim-item-stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-b'), types.uint(1)], deployer.address),
        ]);

        //console.log(chain.getAssetsMaps())
        assertEquals(chain.getAssetsMaps().assets['.nft-a.nft-a'][deployer.address], 0)
        assertEquals(chain.getAssetsMaps().assets['.nft-b.nft-b'][deployer.address], 1)
        assertEquals(chain.getAssetsMaps().assets['.nft-a.nft-a']["ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.staking"], 1)
        claimBlock.receipts[0].result.expectOk().expectBool(true);
        claimBlock.receipts[1].result.expectOk().expectBool(true);
    },
})

// Mint, stake, claim & unstake 1 NFT-A (custodial)
Clarinet.test({
    name: "Can mint, stake (custodial), claim, & unstake 1 NFT-A for 10000 FT",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;

        let startBlock = chain.mineBlock([
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1), types.bool(true)], deployer.address),
            Tx.contractCall("nft-a", "mint-nft-a", [], deployer.address)
        ]);

        //console.log(chain.getAssetsMaps())

        chain.mineEmptyBlock(1);

        let stakeBlock = chain.mineBlock([
            Tx.contractCall("staking", "stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
        ]);
        //console.log(chain.getAssetsMaps())
        stakeBlock.receipts[0].result.expectOk().expectBool(true);

        //chain.mineEmptyBlock(1);

        let claimUnstakeBlock = chain.mineBlock([
            Tx.contractCall("staking", "claim-item-stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
            Tx.contractCall("staking", "unstake-item", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
        ]);

        //console.log(chain.getAssetsMaps())
        //console.log(claimUnstakeBlock.receipts[0].result)

        assertEquals(chain.getAssetsMaps().assets['.ft.example-ft'][deployer.address], 10000)
        //assertEquals(chain.getAssetsMaps().assets['.nft-a.nft-a'][deployer.address], 1)
        claimUnstakeBlock.receipts[0].result.expectOk().expectBool(true);
        claimUnstakeBlock.receipts[1].result.expectOk().expectBool(true);
    },
})

// Mint, stake, claim & unstake 1 NFT-A (custodial) & 1 NFT-B (non-custodial)
Clarinet.test({
    name: "Can mint, stake (custodial), claim, & unstake 1 NFT-A & 1 NFT-B for 4000 FT",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;

        let startBlock = chain.mineBlock([
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1), types.bool(true)], deployer.address),
            Tx.contractCall("staking", "admin-add-new-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-b'), types.uint(1), types.bool(false)], deployer.address),
            Tx.contractCall("nft-a", "mint-nft-a", [], deployer.address),
            Tx.contractCall("nft-b", "mint-nft-b", [], deployer.address)
        ]);

        //console.log(chain.getAssetsMaps())

        chain.mineEmptyBlock(1);

        let stakeBlock = chain.mineBlock([
            Tx.contractCall("staking", "stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
            Tx.contractCall("staking", "stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-b'), types.uint(1)], deployer.address),
        ]);
        //console.log(chain.getAssetsMaps())
        stakeBlock.receipts[0].result.expectOk().expectBool(true);

        chain.mineEmptyBlock(1);

        let claimBlock = chain.mineBlock([
            //Tx.contractCall("staking", "stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
            //Tx.contractCall("staking", "stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-b'), types.uint(1)], deployer.address),
            Tx.contractCall("staking", "claim-item-stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
            Tx.contractCall("staking", "claim-item-stake", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-b'), types.uint(1)], deployer.address),
        ]);

        chain.mineEmptyBlock(1);

        let unstakeBlock = chain.mineBlock([
            Tx.contractCall("staking", "unstake-item", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-a'), types.uint(1)], deployer.address),
            Tx.contractCall("staking", "unstake-item", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-b'), types.uint(1)], deployer.address),
        ]);

        console.log(chain.getAssetsMaps())
        console.log(unstakeBlock.receipts[0].result)
        console.log(unstakeBlock.receipts[1].result)

        assertEquals(chain.getAssetsMaps().assets['.ft.example-ft'][deployer.address], 80000)
        //assertEquals(chain.getAssetsMaps().assets['.nft-a.nft-a'][deployer.address], 1)
        unstakeBlock.receipts[0].result.expectOk().expectBool(true);
        unstakeBlock.receipts[1].result.expectOk().expectBool(true);
    },
})

