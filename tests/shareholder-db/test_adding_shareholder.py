import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_adding_shareholder(deploy_coinbase, deploy_contract, contracts):
    token = deploy_contract(contracts.MillionSharesDB)

    assert token.isShareholder(deploy_coinbase) is False

    token.addShareholder.s(deploy_coinbase)

    assert token.isShareholder(deploy_coinbase) is True


def test_error_to_add_existing_shareholder(deploy_coinbase, deploy_contract,
                                           contracts):
    token = deploy_contract(contracts.MillionSharesDB)

    token.addShareholder.s(deploy_coinbase)

    assert token.isShareholder(deploy_coinbase) is True

    with pytest.raises(TransactionFailed):
        token.addShareholder.s(deploy_coinbase)
