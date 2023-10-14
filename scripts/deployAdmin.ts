import { toNano } from 'ton-core';
import { Admin } from '../wrappers/Admin';
import { NetworkProvider } from '@ton-community/blueprint';

export async function run(provider: NetworkProvider) {
    const admin = provider.open(await Admin.fromInit());

    await admin.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(admin.address);

    // run methods on `admin`
}
