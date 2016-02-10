deploy_contracts = []


def test_balances_not_tracked_prior_to_deposit(deploy_contract, contracts,
                                               deploy_client, deploy_coinbase,
                                               accounts):
    token = deploy_contract(contracts.MillionSharesDB)
    db = deploy_contract(contracts.DividendsDBTest)

    db.setToken.s(token._meta.address)
    token.setDividendsDB.s(db._meta.address)

    assert db.numDeposits() == 0
    assert db.numBalanceRecords(deploy_coinbase) == 0

    token.addShareholder.s(deploy_coinbase)
    token.allocateShares.s(deploy_coinbase, 500000)

    assert token.balanceOf(deploy_coinbase) == 500000
    assert db.numBalanceRecords(deploy_coinbase) == 0

    token.addShareholder.s(accounts[1])
    token.transfer.s(accounts[1], 200000)

    assert token.balanceOf(deploy_coinbase) == 300000
    assert db.numBalanceRecords(deploy_coinbase) == 0

    assert token.balanceOf(accounts[1]) == 200000
    assert db.numBalanceRecords(accounts[1]) == 0


def test_balances_tracked_for_transfers(deploy_contract, contracts,
                                        deploy_client, accounts):
    token = deploy_contract(contracts.MillionSharesDB)
    db = deploy_contract(contracts.DividendsDBTest)

    db.setToken.s(token._meta.address)
    token.setDividendsDB.s(db._meta.address)

    token.addShareholder.s(accounts[0])
    token.allocateShares.s(accounts[0], 500000)

    token.addShareholder.s(accounts[1])
    token.addShareholder.s(accounts[2])
    token.transfer.s(accounts[1], 200000)

    db.deposit(100)
    token.transfer.s(accounts[2], 100000, _from=accounts[1])
    db.deposit(100)
    token.transfer.s(accounts[2], 100000, _from=accounts[1])
    db.deposit(100)
    token.transfer.s(accounts[2], 100000, _from=accounts[0])

    assert db.numBalanceRecords(accounts[0]) == 1
    assert db.balanceAt(accounts[0], 0) == 2
    assert db.balances(accounts[0], 2) == 300000

    assert db.numBalanceRecords(accounts[1]) == 2
    assert db.balanceAt(accounts[1], 0) == 0
    assert db.balances(accounts[1], 0) == 200000
    assert db.balanceAt(accounts[1], 1) == 1
    assert db.balances(accounts[1], 1) == 100000

    assert db.numBalanceRecords(accounts[2]) == 3
    assert db.balanceAt(accounts[2], 0) == 0
    assert db.balances(accounts[2], 0) == 0
    assert db.balanceAt(accounts[2], 1) == 1
    assert db.balances(accounts[2], 1) == 100000
    assert db.balanceAt(accounts[2], 2) == 2
    assert db.balances(accounts[2], 2) == 200000
