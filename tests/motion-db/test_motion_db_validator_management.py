import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


EMPTY_ADDRESS = "0x0000000000000000000000000000000000000000"


def test_setting_motion_db_validator(deploy_contract, contracts, deploy_client,
                                     accounts, get_log_data, deploy_coinbase,
                                     Status):
    motion_db = deploy_contract(contracts.MotionDB)
    validator = deploy_contract(contracts.Validator)

    validator.transferOwnership.s(motion_db._meta.address)

    assert motion_db.validator() == EMPTY_ADDRESS

    motion_db.setValidator.s(validator._meta.address)

    assert motion_db.validator() == validator._meta.address


def test_only_owner_can_set_validator(deploy_contract, contracts,
                                      deploy_client, accounts, get_log_data,
                                      deploy_coinbase, Status):
    motion_db = deploy_contract(contracts.MotionDB)
    validator = deploy_contract(contracts.Validator)

    validator.transferOwnership.s(motion_db._meta.address)

    assert motion_db.validator() == EMPTY_ADDRESS

    with pytest.raises(TransactionFailed):
        motion_db.setValidator.s(validator._meta.address)

    assert motion_db.validator() == EMPTY_ADDRESS


def test_transferring_validator(deploy_contract, contracts, deploy_client,
                                accounts, get_log_data, deploy_coinbase,
                                Status):
    motion_db = deploy_contract(contracts.MotionDB)
    validator = deploy_contract(contracts.Validator)

    validator.transferOwnership.s(motion_db._meta.address)
    motion_db.setValidator.s(validator._meta.address)

    assert validator.owner() == motion_db._meta.address
    assert motion_db.validator() == validator._meta.address

    motion_db.transferValidator(deploy_coinbase)

    assert validator.owner() == deploy_coinbase
    assert motion_db.validator() == EMPTY_ADDRESS


def test_only_owner_can_set_validator(deploy_contract, contracts,
                                      deploy_client, accounts, get_log_data,
                                      deploy_coinbase, Status):
    motion_db = deploy_contract(contracts.MotionDB)
    validator = deploy_contract(contracts.Validator)

    validator.transferOwnership.s(motion_db._meta.address)
    motion_db.setValidator.s(validator._meta.address)

    assert validator.owner() == motion_db._meta.address
    assert motion_db.validator() == validator._meta.address

    with pytest.raises(TransactionFailed):
        motion_db.transferValidator(deploy_coinbase, _from=accounts[1])

    assert validator.owner() == motion_db._meta.address
    assert motion_db.validator() == validator._meta.address
