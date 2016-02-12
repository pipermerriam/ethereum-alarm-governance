import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


EMPTY_ADDRESS = '0x0000000000000000000000000000000000000000'


def test_empty_address_not_recognized_as_valid(deploy_contract, contracts, accounts,
                                               get_log_data):
    token = deploy_contract(contracts.MillionSharesDB)

    assert token.isShareholder(EMPTY_ADDRESS) is False

    with pytest.raises(TransactionFailed):
        token.addShareholder(EMPTY_ADDRESS)


def test_shareholder_lookup_utility_functions(deploy_contract, contracts, accounts,
                                              get_log_data):
    token = deploy_contract(contracts.MillionSharesDB)

    join_blocks = {}

    _, txn_0_r = token.addShareholder.s(accounts[0])
    assert token.isShareholder(accounts[0])

    join_blocks[accounts[0]] = int(txn_0_r['blockNumber'], 16)

    _, txn_1_r = token.addShareholder.s(accounts[1])
    assert token.isShareholder(accounts[1])

    join_blocks[accounts[1]] = int(txn_1_r['blockNumber'], 16)

    _, txn_2_r = token.addShareholder.s(accounts[2])
    assert token.isShareholder(accounts[2])

    join_blocks[accounts[2]] = int(txn_2_r['blockNumber'], 16)

    assert token.getJoinBlock(accounts[0]) == join_blocks[accounts[0]]
    assert token.getJoinBlock(accounts[1]) == join_blocks[accounts[1]]
    assert token.getJoinBlock(accounts[2]) == join_blocks[accounts[2]]

    assert token.queryShareholders('==', join_blocks[accounts[0]]) == accounts[0]
    assert token.queryShareholders('==', join_blocks[accounts[1]]) == accounts[1]
    assert token.queryShareholders('==', join_blocks[accounts[2]]) == accounts[2]

    assert token.queryShareholders('>', 0) == accounts[0]
    assert token.queryShareholders('>=', 0) == accounts[0]

    assert token.queryShareholders('>', join_blocks[accounts[0]]) == accounts[1]
    assert token.queryShareholders('>=', join_blocks[accounts[0]]) == accounts[0]

    assert token.queryShareholders('>', join_blocks[accounts[1]]) == accounts[2]
    assert token.queryShareholders('>=', join_blocks[accounts[1]]) == accounts[1]

    assert token.queryShareholders('>', join_blocks[accounts[2]]) == EMPTY_ADDRESS
    assert token.queryShareholders('>=', join_blocks[accounts[2]]) == accounts[2]

    assert token.queryShareholders('<', join_blocks[accounts[0]]) == EMPTY_ADDRESS
    assert token.queryShareholders('<=', join_blocks[accounts[0]]) == accounts[0]

    assert token.queryShareholders('<', join_blocks[accounts[1]]) == accounts[0]
    assert token.queryShareholders('<=', join_blocks[accounts[1]]) == accounts[1]

    assert token.queryShareholders('<', join_blocks[accounts[2]]) == accounts[1]
    assert token.queryShareholders('<=', join_blocks[accounts[2]]) == accounts[2]

    assert token.getNextShareholder(accounts[0]) == accounts[1]
    assert token.getNextShareholder(accounts[1]) == accounts[2]
    assert token.getNextShareholder(accounts[2]) == EMPTY_ADDRESS

    assert token.getPreviousShareholder(accounts[0]) == EMPTY_ADDRESS
    assert token.getPreviousShareholder(accounts[1]) == accounts[0]
    assert token.getPreviousShareholder(accounts[2]) == accounts[1]
