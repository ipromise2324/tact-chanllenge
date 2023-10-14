import { Blockchain, SandboxContract, TreasuryContract, printTransactionFees } from '@ton-community/sandbox';
import { Slice, beginCell, toNano } from 'ton-core';
import { Admin, Refund } from '../wrappers/Admin';
import { Task2 } from '../wrappers/Task2';
import '@ton-community/test-utils';
import { send } from 'process';

describe('Admin', () => {
    let blockchain: Blockchain;
    let admin: SandboxContract<Admin>;
    let deployer: SandboxContract<TreasuryContract>; 
    let task2: SandboxContract<Task2>;
    beforeEach(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');
        admin = blockchain.openContract(await Admin.fromInit(deployer.address));
        task2 = blockchain.openContract(await Task2.fromInit(admin.address));


        const deployResult = await admin.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: admin.address,
            deploy: true,
            success: true,
        });

        const deployResult2 = await task2.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult2.transactions).toHaveTransaction({
            from: deployer.address,
            to: task2.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and admin are ready to use
    });

    it('should send empty slice', async () => {
        // Send empty message to task2
        const queryIdBefore = await admin.getGetQueryId();
        const msg: Slice = beginCell().endCell().asSlice();
        const result = await task2.send(
            deployer.getSender(),
            {
                value: toNano('1'),
            },
            msg
        );
        //printTransactionFees(result.transactions);

        // Check deployer -> task2
        expect(result.transactions).toHaveTransaction({
            from: deployer.address,
            to: task2.address,
            success: true,
        });

        // Check task2 -> admin
        expect(result.transactions).toHaveTransaction({
            from: task2.address,
            to: admin.address,
            success: true,
        });

        // Check queryId is incremented
        const queryIdAfter = await admin.getGetQueryId();
        expect(queryIdAfter).toEqual(queryIdBefore + 1n);

        // Sedner Refund msg to admin
        const refund: Refund = {
            $$type: 'Refund',
            queryId: 0n,
            sender: task2.address,
        };
        const result2 = await admin.send(
            deployer.getSender(),
            {
                value: toNano('1'),
            },
            refund
        );
        //printTransactionFees(result.transactions);
        
        // Check deployer -> admin
        expect(result2.transactions).toHaveTransaction({
            from: deployer.address,
            to: admin.address,
            success: true,
        });

        // Check admin -> task2
        expect(result2.transactions).toHaveTransaction({
            from: admin.address,
            to: task2.address,
            success: true,
        });

        // Check task2 -> deployer
        expect(result2.transactions).toHaveTransaction({
            from: task2.address,
            to: deployer.address,
            success: true,
        });
    });

    it('should send address slice', async () => {
        // Send empty message to task2
        const queryIdBefore = await admin.getGetQueryId();
        const msg: Slice = beginCell().storeAddress(deployer.address).endCell().asSlice();
        const result = await task2.send(
            deployer.getSender(),
            {
                value: toNano('1'),
            },
            msg
        );
        //printTransactionFees(result.transactions);
        expect(result.transactions).toHaveTransaction({
            from: deployer.address,
            to: task2.address,
            success: true,
        });

        expect(result.transactions).toHaveTransaction({
            from: task2.address,
            to: admin.address,
            success: true,
        });

        const queryIdAfter = await admin.getGetQueryId();
        expect(queryIdAfter).toEqual(queryIdBefore + 1n);

        // Sedner Refund msg to admin
        const refund: Refund = {
            $$type: 'Refund',
            queryId: 0n,
            sender: task2.address,
        };
        const result2 = await admin.send(
            deployer.getSender(),
            {
                value: toNano('1'),
            },
            refund
        );
        //printTransactionFees(result.transactions);
        
        expect(result2.transactions).toHaveTransaction({
            from: deployer.address,
            to: admin.address,
            success: true,
        });

        expect(result2.transactions).toHaveTransaction({
            from: admin.address,
            to: task2.address,
            success: true,
        });

        expect(result2.transactions).toHaveTransaction({
            from: task2.address,
            to: deployer.address,
            success: true,
        });
    });

    it('should message with not enough ton (msg.value < 0.014) should fail', async () => {
        // Send empty message to task2
        const queryIdBefore = await admin.getGetQueryId();
        const msg: Slice = beginCell().storeAddress(deployer.address).endCell().asSlice();
        const result = await task2.send(
            deployer.getSender(),
            {
                value: toNano('0.013'),
            },
            msg
        );
        //printTransactionFees(result.transactions);
        expect(result.transactions).toHaveTransaction({
            from: deployer.address,
            to: task2.address,
            success: true,
        });

        expect(result.transactions).toHaveTransaction({
            from: task2.address,
            to: admin.address,
            success: false,
        });
    });

    it('should Refund message should fail if msg.value is too low', async () => {
        // Send empty message to task2
        const queryIdBefore = await admin.getGetQueryId();
        const msg: Slice = beginCell().storeAddress(deployer.address).endCell().asSlice();
        const result = await task2.send(
            deployer.getSender(),
            {
                value: toNano('1'),
            },
            msg
        );
        //printTransactionFees(result.transactions);
        expect(result.transactions).toHaveTransaction({
            from: deployer.address,
            to: task2.address,
            success: true,
        });

        expect(result.transactions).toHaveTransaction({
            from: task2.address,
            to: admin.address,
            success: true,
        });

        const queryIdAfter = await admin.getGetQueryId();
        expect(queryIdAfter).toEqual(queryIdBefore + 1n);

        // Sedner Refund msg to admin
        const refund: Refund = {
            $$type: 'Refund',
            queryId: 0n,
            sender: task2.address,
        };
        const result2 = await admin.send(
            deployer.getSender(),
            {
                value: toNano('0.018'),
            },
            refund
        );
        printTransactionFees(result2.transactions);
        
        expect(result2.transactions).toHaveTransaction({
            from: deployer.address,
            to: admin.address,
            success: true,
        });

        expect(result2.transactions).toHaveTransaction({
            from: admin.address,
            to: task2.address,
            success: true,
        });

        expect(result2.transactions).toHaveTransaction({
            from: task2.address,
            to: deployer.address,
            success: false,
        });
    });


});
