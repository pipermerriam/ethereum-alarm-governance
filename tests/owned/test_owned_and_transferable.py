import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_ownership_transfer_restrictions_and_execution(deploy_coinbase,
                                                       accounts,
                                                       deploy_contract,
                                                       contracts,
                                                       get_log_data):
    transferable = deploy_contract(contracts.transferable)

    assert transferable.owner() == deploy_coinbase

    with pytest.raises(TransactionFailed):
        transferable.transferOwnership.s(accounts[2], _from=accounts[1])

    assert transferable.owner() == deploy_coinbase

    txn_h, txn_r = transferable.transferOwnership.s(
        accounts[2],
        _from=deploy_coinbase,
    )

    assert transferable.owner() == accounts[2]

    transfer_event_data = get_log_data(transferable.OwnershipTransfer, txn_h)

    assert transfer_event_data['from'] == deploy_coinbase
    assert transfer_event_data['to'] == accounts[2]
