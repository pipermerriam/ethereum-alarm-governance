import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_setting_allowance(deploy_contract, contracts, accounts, get_log_data):
    token = deploy_contract(contracts.MillionSharesDB)

    token.addShareholder.s(accounts[0])
    token.addShareholder.s(accounts[1])

    token.allocateShares.s(accounts[0], 250000)

    assert token.allowance(accounts[0], accounts[1]) == 0

    token.approve.s(accounts[1], 100000, _from=accounts[0])

    assert token.allowance(accounts[0], accounts[1]) == 100000

    txn_h, txn_r = token.approve.s(accounts[1], 50000, _from=accounts[0])

    assert token.allowance(accounts[0], accounts[1]) == 50000

    approve_event_data = get_log_data(token.Approval, txn_h)

    assert approve_event_data['owner'] == accounts[0]
    assert approve_event_data['spender'] == accounts[1]
    assert approve_event_data['value'] == 50000
