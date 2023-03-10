
import { Clarinet, Tx, Chain, Account, Contract, types } from 'https://deno.land/x/clarinet@v0.31.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const stakingContract = "staking";
const defaultNFTContract = "sip-09";
const defaultFTContract = "sip-10";
const nftAContract = "nft-a";

const stakingPrincipal = (deployer: Account) => '${deployer.address}.${stakingContract}';
const nftAPrincipal = (deployer: Account) => '${deployer.address}.${nftAContract}';

// Admin can add NFT-A (custodial) for staking
Clarinet.test({
    name: "Admin can add whitelisted collection",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        const callBefore = chain.callReadOnlyFn("staking", "get-whitelisted-collections", [], deployer.address);
        //console.log(callBefore);

        let block = chain.mineBlock([
            Tx.contractCall("staking", "add-whitelisted-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-staking-a')], deployer.address)
        ]);

        const callAfter = chain.callReadOnlyFn("staking", "get-whitelisted-collections", [], deployer.address);
        //console.log(callAfter);

        //console.log(block.receipts[0]);
        block.receipts[0].result.expectOk().expectBool(true);
    },
})

// Admin can remove whitelisted for staking
Clarinet.test({
    name: "Admin can remove whitelisted collection",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        const callInitial = chain.callReadOnlyFn("staking", "get-whitelisted-collections", [], deployer.address);
        //console.log(callInitial);

        let blockAdd = chain.mineBlock([
            Tx.contractCall("staking", "add-whitelisted-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-staking-a')], deployer.address)
        ]);

        const callBefore = chain.callReadOnlyFn("staking", "get-whitelisted-collections", [], deployer.address);
        //console.log(callBefore);

        chain.mineEmptyBlock(1);

        let blockRemove = chain.mineBlock([
            Tx.contractCall("staking", "remove-whitelisted-collection", [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.nft-staking-a')], deployer.address)
        ]);

        const callAfter = chain.callReadOnlyFn("staking", "get-whitelisted-collections", [], deployer.address);
        console.log(callAfter);

        //console.log(block.receipts[0]);
        blockRemove.receipts[0].result.expectOk().expectBool(true);
    },
})

// Admin can add additional team-admin
Clarinet.test({
    name: "Admin can add team admin",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;

        const callBefore = chain.callReadOnlyFn("staking", "get-team-admins", [], deployer.address);
        //console.log(callBefore);

        let block = chain.mineBlock([
            Tx.contractCall("staking", "add-team-admin", [types.principal(wallet_1.address)], deployer.address)
        ]);

        const callAfter = chain.callReadOnlyFn("staking", "get-team-admins", [], deployer.address);
        //console.log(callAfter);
        
        block.receipts[0].result.expectOk().expectBool(true);
        //console.log(block.receipts[0]);
    },
})

// Admin can remove team-admin
Clarinet.test({
    name: "Admin can remove team admin",
    async fn(chain: Chain, accounts: Map<string, Account>) {

        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;
        const callInitial = chain.callReadOnlyFn("staking", "get-team-admins", [], deployer.address);
        //console.log(callInitial);

        let blockAdd = chain.mineBlock([
            Tx.contractCall("staking", "add-team-admin", [types.principal(wallet_1.address)], deployer.address)
        ]);

        const callBefore = chain.callReadOnlyFn("staking", "get-team-admins", [], deployer.address);
        //console.log(callBefore);

        chain.mineEmptyBlock(1);

        let blockRemove = chain.mineBlock([
            Tx.contractCall("staking", "remove-team-admin", [types.principal(wallet_1.address)], deployer.address)
        ]);

        const callAfter = chain.callReadOnlyFn("staking", "get-team-admins", [], deployer.address);
        console.log(callAfter);

        //console.log(block.receipts[0]);
        blockRemove.receipts[0].result.expectOk().expectBool(true);
    },
})