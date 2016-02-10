# Measured: 41385
STEP_GAS_LOW = 42000


def test_individual_steps_with_no_balance_changes(deploy_coinbase,
                                                  deploy_contract, contracts):
    token = deploy_contract(contracts.MillionSharesDB)
    db = deploy_contract(contracts.DividendsDBTest)

    db.setToken.s(token._meta.address)
    token.setDividendsDB.s(db._meta.address)

    token.addShareholder.s(deploy_coinbase)
    token.allocateShares.s(deploy_coinbase, 1000000)

    for _ in range(25):
        db.deposit.s(100);

    gas_usage = []

    while db.hasUnprocessedDividends(deploy_coinbase):
        deposit_idx = db.depositIdx(deploy_coinbase)
        _, txn_r = db.processNextDeposit.s(deploy_coinbase)
        if deposit_idx == db.depositIdx(deploy_coinbase):
            raise ValueError("didn't advance")
        gas_usage.append(int(txn_r['gasUsed'], 16))

    assert len(gas_usage) == db.numDeposits()

    actual_gas_per_step = sum(gas_usage) / len(gas_usage)
    assert STEP_GAS_LOW > actual_gas_per_step
    assert STEP_GAS_LOW - actual_gas_per_step < 5000


# Measured: 49069
STEP_GAS_HIGH = 50000


def test_individual_steps_with_balance_changes(deploy_coinbase,
                                               deploy_contract, contracts,
                                               accounts):
    token = deploy_contract(contracts.MillionSharesDB)
    db = deploy_contract(contracts.DividendsDBTest)

    db.setToken.s(token._meta.address)
    token.setDividendsDB.s(db._meta.address)

    token.addShareholder.s(deploy_coinbase)
    token.addShareholder.s(accounts[1])
    token.allocateShares.s(deploy_coinbase, 1000000)

    for _ in range(25):
        db.deposit.s(100);
        token.transfer(accounts[1], 100)

    gas_usage = []

    while db.hasUnprocessedDividends(deploy_coinbase):
        deposit_idx = db.depositIdx(deploy_coinbase)
        _, txn_r = db.processNextDeposit.s(deploy_coinbase)
        if deposit_idx == db.depositIdx(deploy_coinbase):
            raise ValueError("didn't advance")
        gas_usage.append(int(txn_r['gasUsed'], 16))

    assert len(gas_usage) == db.numDeposits()

    actual_gas_per_step = sum(gas_usage) / len(gas_usage)
    assert STEP_GAS_HIGH > actual_gas_per_step
    assert STEP_GAS_HIGH - actual_gas_per_step < 5000


# Measured: 40786
LOOP_GAS_LOW = 41000


def test_loop_processing_without_balance_changes(deploy_coinbase,
                                                 deploy_contract, contracts,
                                                 accounts):
    token = deploy_contract(contracts.MillionSharesDB)
    db = deploy_contract(contracts.DividendsDBTest)

    db.setToken.s(token._meta.address)
    token.setDividendsDB.s(db._meta.address)

    token.addShareholder.s(deploy_coinbase)
    token.allocateShares.s(deploy_coinbase, 1000000)

    for _ in range(150):
        db.deposit.s(100);

    gas_usage = []

    while db.hasUnprocessedDividends(deploy_coinbase):
        deposit_idx = db.depositIdx(deploy_coinbase)
        _, txn_r = db.processNextDeposit.s(deploy_coinbase)
        if deposit_idx == db.depositIdx(deploy_coinbase):
            raise ValueError("didn't advance")
        gas_usage.append(int(txn_r['gasUsed'], 16))

    assert len(gas_usage) == db.numDeposits()

    actual_gas_per_step = sum(gas_usage) / db.numDeposits()
    assert LOOP_GAS_LOW > actual_gas_per_step
    assert LOOP_GAS_LOW - actual_gas_per_step < 5000


# Measured: 47255
LOOP_GAS_HIGH = 48000


def test_loop_processing_with_balance_changes(deploy_coinbase,
                                              deploy_contract, contracts,
                                              accounts):
    token = deploy_contract(contracts.MillionSharesDB)
    db = deploy_contract(contracts.DividendsDBTest)

    db.setToken.s(token._meta.address)
    token.setDividendsDB.s(db._meta.address)

    token.addShareholder.s(deploy_coinbase)
    token.addShareholder.s(accounts[1])
    token.allocateShares.s(deploy_coinbase, 1000000)

    for _ in range(150):
        db.deposit.s(100);
        token.transfer(accounts[1], 100)

    gas_usage = []

    while db.hasUnprocessedDividends(deploy_coinbase):
        deposit_idx = db.depositIdx(deploy_coinbase)
        _, txn_r = db.processNextDeposit.s(deploy_coinbase)
        if deposit_idx == db.depositIdx(deploy_coinbase):
            raise ValueError("didn't advance")
        gas_usage.append(int(txn_r['gasUsed'], 16))

    assert len(gas_usage) == db.numDeposits()

    actual_gas_per_step = sum(gas_usage) / db.numDeposits()
    assert LOOP_GAS_HIGH > actual_gas_per_step
    assert LOOP_GAS_HIGH - actual_gas_per_step < 5000
