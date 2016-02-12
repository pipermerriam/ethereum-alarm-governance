import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_transfers_and_balance_tracked_correctly(deploy_contract, contracts,
                                                 accounts):
    token = deploy_contract(contracts.MillionSharesDB)

    token.addShareholder.s(accounts[0])
    token.addShareholder.s(accounts[1])

    token.allocateShares.s(accounts[0], 250000)

    assert token.balanceOf(accounts[0]) == 250000
    assert token.balanceOf(accounts[1]) == 0

    token.transfer.s(accounts[1], 100000, _from=accounts[0])

    assert token.balanceOf(accounts[0]) == 150000
    assert token.balanceOf(accounts[1]) == 100000

    token.transfer.s(accounts[1], 75000, _from=accounts[0])

    assert token.balanceOf(accounts[0]) == 75000
    assert token.balanceOf(accounts[1]) == 175000


def test_insufficient_funds_transfer_fails(deploy_contract, contracts,
                                           accounts, get_log_data):
    token = deploy_contract(contracts.MillionSharesDB)

    token.addShareholder.s(accounts[0])
    token.addShareholder.s(accounts[1])

    token.allocateShares.s(accounts[0], 250000)

    assert token.balanceOf(accounts[0]) == 250000
    assert token.balanceOf(accounts[1]) == 0

    txn_h, txn_r = token.transfer.s(accounts[1], 250001, _from=accounts[0])

    # no change
    assert token.balanceOf(accounts[0]) == 250000
    assert token.balanceOf(accounts[1]) == 0

    with pytest.raises(AssertionError):
        get_log_data(token.Transfer, txn_h)


def test_transfer_logs_event(deploy_contract, contracts, accounts,
                             get_log_data):
    token = deploy_contract(contracts.MillionSharesDB)

    token.addShareholder.s(accounts[0])
    token.addShareholder.s(accounts[1])

    token.allocateShares.s(accounts[0], 250000)

    assert token.balanceOf(accounts[0]) == 250000
    assert token.balanceOf(accounts[1]) == 0

    txn_h, txn_r = token.transfer.s(accounts[1], 250000, _from=accounts[0])

    transfer_event_data = get_log_data(token.Transfer, txn_h)

    assert transfer_event_data['from'] == accounts[0]
    assert transfer_event_data['to'] == accounts[1]
    assert transfer_event_data['value'] == 250000
