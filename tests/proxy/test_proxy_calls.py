import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_non_owner_cannot_call(deploy_contract, contracts, accounts,
                               deploy_coinbase):
    logger = deploy_contract(contracts.CallDataLogger)
    proxy = deploy_contract(contracts.Proxy)

    assert proxy.owner() == deploy_coinbase

    with pytest.raises(TransactionFailed):
        proxy.__forward.s(
            logger._meta.address, 0, 0, "abcd",
            _from=accounts[1],
        )

    assert logger.wasCalled() is False

    proxy.__forward.s(
        logger._meta.address, 0, 0, "abcd",
        _from=deploy_coinbase,
    )
    assert logger.wasCalled() is True


def test_proxy_logs_actions(deploy_contract, contracts, deploy_coinbase):
    logger = deploy_contract(contracts.CallDataLogger)
    proxy = deploy_contract(contracts.Proxy)

    assert logger.wasCalled() is False
    assert proxy.numActions() == 0

    txn_h, txn_r = proxy.__forward.s(logger._meta.address, 123, 1000000, "abcd", value=123)

    assert proxy.numActions() == 1
    _id, owner, to, call_data, value, gas, was_successful = proxy.actions(1)

    assert _id == 1
    assert owner == deploy_coinbase
    assert to == logger._meta.address
    assert call_data == "abcd"
    assert value == 123
    assert gas == 1000000
    assert was_successful is True


def test_proxy_with_gas_and_value_data(deploy_contract, contracts):
    logger = deploy_contract(contracts.CallDataLogger)
    proxy = deploy_contract(contracts.Proxy)

    assert logger.wasCalled() is False

    txn_h, txn_r = proxy.__forward.s(logger._meta.address, 123, 1000000, "abcd", value=123)

    assert logger.wasCalled() is True
    assert logger.value() == 123
    assert abs(logger.gas() - 1000000) < 3000
    assert logger.data() == "abcd\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
    assert logger.msgSender() == proxy._meta.address


def test_proxy_with_gas_but_no_value(deploy_contract, contracts):
    logger = deploy_contract(contracts.CallDataLogger)
    proxy = deploy_contract(contracts.Proxy)

    assert logger.wasCalled() is False

    txn_h, txn_r = proxy.__forward.s(logger._meta.address, 0, 1000000, "abcd")

    assert logger.wasCalled() is True
    assert logger.value() == 0
    assert abs(logger.gas() - 1000000) < 3000
    assert logger.data() == "abcd\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
    assert logger.msgSender() == proxy._meta.address


def test_proxy_with_value_but_no_gas(deploy_contract, contracts):
    logger = deploy_contract(contracts.CallDataLogger)
    proxy = deploy_contract(contracts.Proxy)

    assert logger.wasCalled() is False

    txn_h, txn_r = proxy.__forward.s(logger._meta.address, 123, 0, "abcd", value=123)

    assert logger.wasCalled() is True
    assert logger.value() == 123
    assert logger.data() == "abcd\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
    assert logger.msgSender() == proxy._meta.address


def test_proxy_with_no_value_and_no_gas(deploy_contract, contracts):
    logger = deploy_contract(contracts.CallDataLogger)
    proxy = deploy_contract(contracts.Proxy)

    assert logger.wasCalled() is False

    txn_h, txn_r = proxy.__forward.s(logger._meta.address, 0, 0, "abcd")

    assert logger.wasCalled() is True
    assert logger.value() == 0
    assert logger.data() == "abcd\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
    assert logger.msgSender() == proxy._meta.address
