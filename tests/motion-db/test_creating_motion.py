
import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = [
    "ShareholderDBOwner"
]


EMPTY_ADDRESS = "0x0000000000000000000000000000000000000000"


def test_creating_a_motion(deploy_contract, contracts, deploy_client, accounts,
                           get_log_data, deploy_coinbase, Status):
    motion_db = deploy_contract(contracts.MotionDB)
    validator = deploy_contract(contracts.Validator)
    factory = deploy_contract(
        contracts.MotionFactory,
        constructor_args=("ipfs://example", "1.2.3", "--example"),
    )

    validator.transferOwnership.s(motion_db._meta.address)
    motion_db.setValidator.s(validator._meta.address)

    factory.transferOwnership.s(motion_db._meta.address)
    motion_db.setFactory(factory._meta.address)

    assert motion_db.validator() == validator._meta.address
