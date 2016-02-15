import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_motion_factory_transfers_ownership_on_creation(deploy_contract,
                                                        contracts,
                                                        deploy_client,
                                                        accounts, get_log_data,
                                                        deploy_coinbase):
    factory = deploy_contract(contracts.MotionFactory)

    txn_h, txn_r = factory.deployContract.s(accounts[2])

    deploy_log_data = get_log_data(factory.Deployed, txn_h)

    motion_addr = deploy_log_data['addr']
    motion = contracts.MotionInterface(motion_addr, deploy_client)

    assert motion.owner() == deploy_coinbase
    assert motion.createdBy() == accounts[2]
