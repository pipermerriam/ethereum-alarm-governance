import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_removing_shareholder(deploy_contract, contracts):
    token = deploy_contract(contracts.MillionSharesDB)

    assert token.totalSupply() == 1000000
