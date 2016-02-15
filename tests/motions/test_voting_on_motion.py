import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_voting_on_motion(deploy_contract, contracts, deploy_client, accounts,
                          get_log_data, deploy_coinbase, Status,
                          deployed_contracts, deploy_constellation):
    constellation = deploy_constellation(
        additional_shareholders=accounts[1:10],
        validation_minimums={'quorum_size': 3, 'debate_period': 5, 'pass_percentage': 51},
    )

    factory = constellation.factory
    motion_db = constellation.motion_db

    create_txn_h, create_txn_r = motion_db.create.s()
    create_logs = get_log_data(factory.Deployed, create_txn_h)

    motion = contracts.Motion(create_logs['addr'], deploy_client)

    motion.configure.s(3, 5, 51, accounts[2])
    motion_db.validate.s(motion._meta.address)

    assert motion.status() == Status.Open

    assert False
