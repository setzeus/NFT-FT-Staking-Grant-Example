
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.31.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensure that <...>",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let block = chain.mineBlock([
            /* 
             * Add transactions with: 
             * Tx.contractCall(...)
            */
        ]);
        assertEquals(block.receipts.length, 0);
        assertEquals(block.height, 2);

        block = chain.mineBlock([
            /* 
             * Add transactions with: 
             * Tx.contractCall(...)
            */
        ]);
        assertEquals(block.receipts.length, 0);
        assertEquals(block.height, 3);
    },
});

// Can't test adding new collections...unsure how to pass traits as parameters in tests
// Clarinet.test({
//     name: "Admin can add a new collection to the appropriate lists (custodial)",
//     async fn(chain: Chain, accounts: Map<string, Account>) {

//         let deployer = accounts.get('deployer')!;
//         let wallet_1 = accounts.get('wallet_1')!;

//         let block = chain.mineBlock([
//             Tx.contractCall("staking", "admin-add-new-collection", [], wallet_1.address)
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
// })