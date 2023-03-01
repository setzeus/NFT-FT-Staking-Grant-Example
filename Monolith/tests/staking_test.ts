
import { Clarinet, Tx, Chain, Account, Contract, types } from 'https://deno.land/x/clarinet@v0.31.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';


// function mintNft(
//     { chain, deployer, recipient, nftAssetContract = defaultNFTContract }: {
//       chain: Chain;
//       deployer: Account;
//       recipient: Account;
//       nftAssetContract?: string;
//     },
//   ) {
//     const block = chain.mineBlock([
//       Tx.contractCall(nftAssetContract, "mint", [
//         types.principal(recipient.address),
//       ], deployer.address),
//     ]);
//     block.receipts[0].result.expectOk();
//     const nftMintEvent = block.receipts[0].events[0].nft_mint_event;
//     const [nftAssetContractPrincipal, nftAssetId] = nftMintEvent.asset_identifier
//       .split("::");
//     console.log([nftAssetContractPrincipal, nftAssetId])
//     return {
//       nftAssetContract: nftAssetContractPrincipal,
//       nftAssetId,
//       tokenId: nftMintEvent.value.substr(1),
//       block,
//     };
//   }

// Clarinet.test({
//     name: "Ensure that <...>",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
//         let block = chain.mineBlock([
//             /* 
//              * Add transactions with: 
//              * Tx.contractCall(...)
//             */
//         ]);
//         assertEquals(block.receipts.length, 0);
//         assertEquals(block.height, 2);

//         block = chain.mineBlock([
//             /* 
//              * Add transactions with: 
//              * Tx.contractCall(...)
//             */
//         ]);
//         assertEquals(block.receipts.length, 0);
//         assertEquals(block.height, 3);
//     },
// });

const stakingContract = "staking";

const defaultNFTContract = "sip-09";
const defaultFTContract = "sip-10";
const nftAContract = "nft-a";

const stakingPrincipal = (deployer: Account) => '${deployer.address}.${stakingContract}';
const nftAPrincipal = (deployer: Account) => '${deployer.address}.${nftAContract}';

// Can't test adding new collections...unsure how to pass traits as parameters in tests
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