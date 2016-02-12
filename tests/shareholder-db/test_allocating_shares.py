import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_allocating_shares(deploy_coinbase, deploy_contract, contracts):
    token = deploy_contract(contracts.MillionSharesDB)

    token.addShareholder.s(deploy_coinbase)

    assert token.isShareholder(deploy_coinbase) is True

    assert token.unallocatedShares() == 1000000

    token.allocateShares.s(deploy_coinbase, 1000000)

    assert token.unallocatedShares() == 0


def test_cannot_overallocate(deploy_coinbase, deploy_contract, contracts):
    token = deploy_contract(contracts.MillionSharesDB)

    token.addShareholder.s(deploy_coinbase)

    assert token.isShareholder(deploy_coinbase) is True

    assert token.unallocatedShares() == 1000000

    token.allocateShares.s(deploy_coinbase, 1000000)

    assert token.unallocatedShares() == 0

    with pytest.raises(TransactionFailed):
        token.allocateShares.s(deploy_coinbase, 1)


def test_cannot_initial_overallocate(deploy_coinbase, deploy_contract, contracts):
    token = deploy_contract(contracts.MillionSharesDB)

    token.addShareholder.s(deploy_coinbase)

    assert token.isShareholder(deploy_coinbase) is True

    with pytest.raises(TransactionFailed):
        token.allocateShares.s(deploy_coinbase, 1000001)
