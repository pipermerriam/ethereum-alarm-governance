deploy_contracts = []


def test_deposits_are_tracked(deploy_contract, contracts, deploy_client):
    token = deploy_contract(contracts.MillionSharesDB)
    db = deploy_contract(contracts.DividendsDBTest)

    db.setToken.s(token._meta.address)

    assert db.numDeposits() == 0

    db.deposit(100)

    assert db.numDeposits() == 1
    assert db.deposits(0) == 100

    db.deposit(90)

    assert db.numDeposits() == 2
    assert db.deposits(0) == 100
    assert db.deposits(1) == 90

    db.deposit(80)

    assert db.numDeposits() == 3
    assert db.deposits(0) == 100
    assert db.deposits(1) == 90
    assert db.deposits(2) == 80
