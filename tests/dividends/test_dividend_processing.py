deploy_contracts = []


def test_basic_dividend_processing(accounts, deploy_contract,
                                   contracts, py_dividends):
    token = deploy_contract(contracts.MillionSharesDB)
    db = deploy_contract(contracts.DividendsDBTest)

    db.setToken.s(token._meta.address)
    token.setDividendsDB.s(db._meta.address)

    token.addShareholder.s(accounts[0])
    token.addShareholder.s(accounts[1])
    token.addShareholder.s(accounts[2])

    token.allocateShares.s(accounts[0], 1000000)

    supply = 1000000
    init_balances = (
        (accounts[0], supply),
    )
    earnings = (
        (1, 100),
        (3, 100),
        (5, 100),
        (7, 100),
        (8, 100),
    )

    # transfers are in the format (when, from, to, value)
    transfers = (
        (2, accounts[0], accounts[1], 400000),
        (4, accounts[0], accounts[2], 100000),
        (6, accounts[1], accounts[2], 100000),
    )

    balances, ledger = py_dividends.process_transfers(init_balances, transfers)
    expected = py_dividends.compute_dividends(balances, ledger, earnings)

    db.deposit.s(100);
    token.transfer.s(accounts[1], 400000, _from=accounts[0])
    db.deposit.s(100);
    token.transfer.s(accounts[2], 100000, _from=accounts[0])
    db.deposit.s(100);
    token.transfer.s(accounts[2], 100000, _from=accounts[1])
    db.deposit.s(100);
    db.deposit.s(100);

    for acct in accounts[:3]:
        while db.hasUnprocessedDividends(acct):
            deposit_idx = db.depositIdx(acct)
            db.processDividends.s(acct)
            if deposit_idx == db.depositIdx(acct):
                raise ValueError("did not advance!")

    actual = dict((
        (acct, db.dividendBalance(acct)) for acct in accounts[:3]
    ))

    assert actual == expected


def test_more_dividend_processing(accounts, deploy_contract,
                                   contracts, py_dividends):
    token = deploy_contract(contracts.MillionSharesDB)
    db = deploy_contract(contracts.DividendsDBTest)

    db.setToken.s(token._meta.address)
    token.setDividendsDB.s(db._meta.address)

    token.addShareholder.s(accounts[0])
    token.addShareholder.s(accounts[1])
    token.addShareholder.s(accounts[2])

    token.allocateShares.s(accounts[0], 1000000)

    supply = 1000000
    init_balances = (
        (accounts[0], supply),
    )
    transfers = (
        (2, accounts[0], accounts[1], 100000),
        (4, accounts[0], accounts[1], 100000),
        (7, accounts[1], accounts[2], 100000),
    )

    earnings = (
        (1, 100),
        (3, 100),
        (5, 100),
        (6, 100),
    )

    balances, ledger = py_dividends.process_transfers(init_balances, transfers)
    expected = py_dividends.compute_dividends(balances, ledger, earnings)

    db.deposit.s(100);
    token.transfer.s(accounts[1], 100000, _from=accounts[0])
    db.deposit.s(100);
    token.transfer.s(accounts[1], 100000, _from=accounts[0])
    db.deposit.s(100);
    db.deposit.s(100);
    token.transfer.s(accounts[2], 100000, _from=accounts[1])

    for acct in accounts[:3]:
        while db.hasUnprocessedDividends(acct):
            deposit_idx = db.depositIdx(acct)
            db.processDividends.s(acct)
            if deposit_idx == db.depositIdx(acct):
                raise ValueError("did not advance!")

    actual = dict((
        (acct, db.dividendBalance(acct)) for acct in accounts[:3]
    ))

    assert actual == expected
