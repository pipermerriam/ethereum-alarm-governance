import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_creating_a_motion(deploy_contract, contracts, deploy_client, accounts,
                           get_log_data, deploy_coinbase, Status,
                           deployed_contracts, deploy_constellation):
    constellation = deploy_constellation(additional_shareholders=accounts[1:2])

    factory = constellation.factory
    motion_db = constellation.motion_db

    create_txn_h, create_txn_r = motion_db.create.s(_from=accounts[1])
    create_logs = get_log_data(factory.Deployed, create_txn_h)

    motion = contracts.Motion(create_logs['addr'], deploy_client)

    assert motion.createdBy() == accounts[1]


def test_motion_creation_restricted_to_shareholders(deploy_contract, contracts,
                                                    deploy_client, accounts,
                                                    get_log_data,
                                                    deploy_coinbase,
                                                    deploy_constellation):
    constellation = deploy_constellation()

    motion_db = constellation.motion_db

    assert constellation.shareholder_db.isShareholder(accounts[1]) is False

    with pytest.raises(TransactionFailed):
        motion_db.create.s(_from=accounts[1])
