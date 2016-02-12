import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_transferring_from_other_account(deploy_contract, contracts, accounts,
                                         get_log_data):
    token = deploy_contract(contracts.MillionSharesDB)

    token.addShareholder.s(accounts[0])
    token.addShareholder.s(accounts[1])
    token.addShareholder.s(accounts[2])

    token.allocateShares.s(accounts[0], 250000)

    assert token.allowance(accounts[0], accounts[1]) == 0

    token.approve.s(accounts[1], 100000, _from=accounts[0])

    assert token.allowance(accounts[0], accounts[1]) == 100000

    txn_h, txn_r = token.transferFrom.s(accounts[0], accounts[2], 75000, _from=accounts[1])

    assert token.allowance(accounts[0], accounts[1]) == 25000
    assert token.balanceOf(accounts[0]) == 175000
    assert token.balanceOf(accounts[2]) == 75000

    transfer_event_data = get_log_data(token.Transfer, txn_h)

    assert transfer_event_data['from'] == accounts[0]
    assert transfer_event_data['to'] == accounts[2]
    assert transfer_event_data['value'] == 75000

    txn_h, txn_r = token.transferFrom.s(accounts[0], accounts[2], 25000, _from=accounts[1])

    assert token.allowance(accounts[0], accounts[1]) == 0
    assert token.balanceOf(accounts[0]) == 150000
    assert token.balanceOf(accounts[2]) == 100000


def test_cannot_exceed_approved_limit(deploy_contract, contracts, accounts,
                                      get_log_data):
    token = deploy_contract(contracts.MillionSharesDB)

    token.addShareholder.s(accounts[0])
    token.addShareholder.s(accounts[1])
    token.addShareholder.s(accounts[2])

    token.allocateShares.s(accounts[0], 250000)

    token.approve.s(accounts[1], 100000, _from=accounts[0])

    assert token.allowance(accounts[0], accounts[1]) == 100000

    txn_h, txn_r = token.transferFrom.s(accounts[0], accounts[2], 100001, _from=accounts[1])

    assert token.allowance(accounts[0], accounts[1]) == 100000
    assert token.balanceOf(accounts[0]) == 250000
    assert token.balanceOf(accounts[2]) == 0

    with pytest.raises(AssertionError):
        get_log_data(token.Transfer, txn_h)


def test_cannot_exceed_source_account_balance(deploy_contract, contracts,
                                              accounts, get_log_data):
    token = deploy_contract(contracts.MillionSharesDB)

    token.addShareholder.s(accounts[0])
    token.addShareholder.s(accounts[1])
    token.addShareholder.s(accounts[2])

    token.allocateShares.s(accounts[0], 250000)

    token.approve.s(accounts[1], 500000, _from=accounts[0])

    assert token.allowance(accounts[0], accounts[1]) == 500000

    txn_h, txn_r = token.transferFrom.s(accounts[0], accounts[2], 250001, _from=accounts[1])

    assert token.allowance(accounts[0], accounts[1]) == 500000
    assert token.balanceOf(accounts[0]) == 250000
    assert token.balanceOf(accounts[2]) == 0

    with pytest.raises(AssertionError):
        get_log_data(token.Transfer, txn_h)

    token.transferFrom.s(accounts[0], accounts[2], 250000, _from=accounts[1])

    assert token.allowance(accounts[0], accounts[1]) == 250000
    assert token.balanceOf(accounts[0]) == 0
    assert token.balanceOf(accounts[2]) == 250000


def test_cannot_transfer_to_non_shareholder(deploy_contract, contracts,
                                            accounts, get_log_data):
    token = deploy_contract(contracts.MillionSharesDB)

    token.addShareholder.s(accounts[0])
    token.addShareholder.s(accounts[1])

    token.allocateShares.s(accounts[0], 250000)

    token.approve.s(accounts[1], 100000, _from=accounts[0])

    assert token.allowance(accounts[0], accounts[1]) == 100000

    txn_h, txn_r = token.transferFrom.s(accounts[0], accounts[2], 50000, _from=accounts[1])

    assert token.allowance(accounts[0], accounts[1]) == 100000
    assert token.balanceOf(accounts[0]) == 250000
    assert token.balanceOf(accounts[2]) == 0

    with pytest.raises(AssertionError):
        get_log_data(token.Transfer, txn_h)
