import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_removing_shareholder(deploy_coinbase, deploy_contract, contracts):
    token = deploy_contract(contracts.MillionSharesDB)

    assert token.isShareholder(deploy_coinbase) is False

    token.addShareholder.s(deploy_coinbase)

    assert token.isShareholder(deploy_coinbase) is True

    token.removeShareholder.s(deploy_coinbase)

    assert token.isShareholder(deploy_coinbase) is False


def test_error_to_remove_non_shareholder(deploy_coinbase, deploy_contract,
                                         contracts):
    token = deploy_contract(contracts.MillionSharesDB)

    assert token.isShareholder(deploy_coinbase) is False
    assert token.balanceOf(deploy_coinbase) == 0

    with pytest.raises(TransactionFailed):
        token.removeShareholder.s(deploy_coinbase)


def test_shares_moved_to_unallocated_pool(deploy_coinbase, deploy_contract,
                                          contracts):
    token = deploy_contract(contracts.MillionSharesDB)

    token.addShareholder.s(deploy_coinbase)
    token.allocateShares.s(deploy_coinbase, 100)

    assert token.isShareholder(deploy_coinbase) is True
    assert token.balanceOf(deploy_coinbase) == 100

    before_unallocated = token.unallocatedShares()

    token.removeShareholder.s(deploy_coinbase)

    assert token.isShareholder(deploy_coinbase) is False
    assert token.balanceOf(deploy_coinbase) == 0

    after_unallocated = token.unallocatedShares()

    assert after_unallocated == before_unallocated + 100
