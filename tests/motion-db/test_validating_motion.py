import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_validating_a_motion(deploy_contract, contracts, deploy_client,
                             accounts, get_log_data, deploy_coinbase, Status,
                             deployed_contracts, deploy_constellation):
    constellation = deploy_constellation(
        additional_shareholders=accounts[1:2],
        validation_minimums={'quorum_size': 40, 'debate_period': 360, 'pass_percentage': 51},
    )

    factory = constellation.factory
    motion_db = constellation.motion_db

    create_txn_h, create_txn_r = motion_db.create.s(_from=accounts[1])
    create_logs = get_log_data(factory.Deployed, create_txn_h)

    motion = contracts.Motion(create_logs['addr'], deploy_client)

    motion.configure.s(40, 360, 51, accounts[2], _from=accounts[1])

    assert motion.status() == Status.NeedsValidation

    motion_db.validate.s(motion._meta.address)

    assert motion.status() == Status.Open


def test_validating_an_invalid_motion(deploy_contract, contracts,
                                      deploy_client, accounts, get_log_data,
                                      deploy_coinbase, Status,
                                      deployed_contracts,
                                      deploy_constellation):
    constellation = deploy_constellation(
        additional_shareholders=accounts[1:2],
        validation_minimums={'quorum_size': 40, 'debate_period': 360, 'pass_percentage': 51},
    )

    factory = constellation.factory
    motion_db = constellation.motion_db

    create_txn_h, create_txn_r = motion_db.create.s(_from=accounts[1])
    create_logs = get_log_data(factory.Deployed, create_txn_h)

    motion = contracts.Motion(create_logs['addr'], deploy_client)

    motion.configure.s(39, 360, 51, accounts[2], _from=accounts[1])

    assert motion.status() == Status.NeedsValidation

    motion_db.validate.s(motion._meta.address)

    assert motion.status() == Status.NeedsConfiguration
