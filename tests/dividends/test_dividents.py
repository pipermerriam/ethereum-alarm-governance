import decimal
import time
import itertools
import collections
import random


deploy_contracts = [
    "MillionSharesDB",
]



def pairwise(iterable):
    "s -> (s0,s1), (s1,s2), (s2, s3), ..."
    a, b = itertools.tee(iterable)
    next(b, None)
    return itertools.izip(a, b)


def balance_at(when, history):
    if not history:
        return 0

    markers, balances = zip(*history)
    for bounds, balance in zip(pairwise(markers), balances):
        left, right = bounds
        if left <= when < right:
            return balance
    last = history[-1]
    if last[0] <= when:
        return last[1]
    return 0


def compute_dividends(init_balances, transfers, earnings):
    balance_history = collections.defaultdict(list)

    balance_lookup = collections.defaultdict(int)
    balance_lookup.update(dict(init_balances))

    for acct, balance in init_balances:
        balance_history[acct].append((0, balance))

    for when, _from, to, value in transfers:
        if balance_lookup[_from] < value:
            raise ValueError("Insufficient balance")
        balance_lookup[_from] -= value
        balance_lookup[to] += value
        balance_history[_from].append((when, balance_lookup[_from]))
        balance_history[to].append((when, balance_lookup[to]))

    dividends = collections.defaultdict(int)

    total_supply = decimal.Decimal(sum(zip(*init_balances)[1]))

    for when, value in earnings:
        for acct in balance_history.keys():
            bal = balance_at(when, balance_history[acct])
            dividends[acct] += balance_at(when, balance_history[acct]) * value
    return set(dividends.items())


def test_basic_dividends():
    # balances are in the format (who, initial_balance)
    supply = 1000000
    init_balances = (
        ('A', supply),
    )
    # earnings are earnings in the format (when, how_much)
    earnings = (
        (1, 100),
        (2, 100),
        (3, 100),
    )

    # transfers are in the format (when, from, to, value)
    transfers = (
        (1, 'A', 'B', 500000),
    )

    actual = compute_dividends(init_balances, transfers, earnings)

    expected = {
        ('A', 200 * supply),
        ('B', 100 * supply),
    }

    assert actual == expected


def test_more_basic_dividends():
    # balances are in the format (who, initial_balance)
    supply = 1000000
    init_balances = (
        ('A', supply),
    )
    # earnings are earnings in the format (when, how_much)
    earnings = (
        (1, 100),
        (2, 100),
        (3, 100),
        (4, 100),
        (5, 100),
        (6, 100),
        (7, 100),
        (8, 100),
        (9, 100),
    )

    # transfers are in the format (when, from, to, value)
    transfers = (
        (1, 'A', 'B', 500000),
        (2, 'B', 'C', 500000),
        (3, 'A', 'B', 200000),
        (6, 'B', 'D', 100000),
    )

    actual = compute_dividends(init_balances, transfers, earnings)

    expected = {
        ('A', (100 + 50 * 2 + 30 * 6) * supply),
        ('B', (50 + 20 * 3 + 10 * 3) * supply),
        ('C', (50 * 7) * supply),
        ('D', (10 * 3) * supply),
    }

    assert actual == expected


def test_shareholder_db(deployed_contracts, deploy_client, accounts,
                        deploy_coinbase, denoms):
    db = deployed_contracts.MillionSharesDB

    assert db.isShareholder(deploy_coinbase) is False
    assert db.balanceOf(deploy_coinbase) == 0

    db.addShareholder.s(deploy_coinbase)

    assert db.isShareholder(deploy_coinbase) is True
    assert db.balanceOf(deploy_coinbase) == 0

    assert db.unallocatedShares() == 1000000
    db.allocateShares.s(deploy_coinbase, 1000000)

    assert db.balanceOf(deploy_coinbase) == 1000000
    assert db.hasPendingDividends(deploy_coinbase) is False
    assert db.dividends(deploy_coinbase) == 0

    deposit_1 = deploy_client.send_transaction(to=db._meta.address, value=1)
    deploy_client.wait_for_transaction(deposit_1)

    assert db.hasPendingDividends(deploy_coinbase) is True
    db.processDividends.s(deploy_coinbase)
    assert db.hasPendingDividends(deploy_coinbase) is False
    assert db.dividends(deploy_coinbase) == 1000000

    db.addShareholder.s(accounts[1])
    db.transfer.s(accounts[1], 250000)

    assert db.balanceOf(deploy_coinbase) == 750000
    assert db.balanceOf(accounts[1]) == 250000

    deposit_2 = deploy_client.send_transaction(to=db._meta.address, value=2)
    deploy_client.wait_for_transaction(deposit_2)

    assert db.hasPendingDividends(deploy_coinbase) is True
    assert db.hasPendingDividends(accounts[1]) is True

    db.processDividends.s(deploy_coinbase)
    db.processDividends.s(accounts[1])
    db.processDividends.s(accounts[1])

    assert db.hasPendingDividends(deploy_coinbase) is False
    assert db.hasPendingDividends(accounts[1]) is False

    assert db.dividends(deploy_coinbase) == 2500000
    assert db.dividends(accounts[1]) == 500000


def test_dynamic_shareholder_db(deployed_contracts, deploy_client, accounts,
                                deploy_coinbase, denoms):
    db = deployed_contracts.MillionSharesDB

    db.addShareholder.s(deploy_coinbase)
    db.allocateShares.s(deploy_coinbase, db.unallocatedShares())

    assert db.balanceOf(deploy_coinbase) == 1000000

    deploy_client.async_timeout = 60

    init_balances = (
        (accounts[0], 1000000),
    )
    earnings = []
    transfers = []
    shareholders = set([accounts[0]])

    def transfer():
        _from = random.choice(list(shareholders))
        to = random.choice(list(set(accounts).difference([_from])))
        amount = random.randint(0, db.balanceOf(_from))

        if to not in shareholders:
            db.addShareholder(to)
            shareholders.add(to)
        txn_h, txn_r = db.transfer.s(to, amount, _from=_from)
        transfers.append((
            int(txn_r['blockNumber'], 16),
            _from,
            to,
            amount,
        ))

    def deposit():
        amount = random.randint(1, 100)
        txn_h = deploy_client.send_transaction(
            to=db._meta.address,
            value=amount,
        )
        txn_r = deploy_client.wait_for_transaction(txn_h)
        earnings.append((
            int(txn_r['blockNumber'], 16),
            amount,
        ))

    for i in range(10):
        if random.randint(0, i) <= i ** (0.5):
            transfer()
        else:
            deposit()

    receipts = []
    gas = []

    for shareholder in shareholders:
        txn_h, txn_r = db.processDividends.s(shareholder)
        receipts.append(txn_r)
        gas.append(int(txn_r['gasUsed'], 16))

    expected = compute_dividends(init_balances, transfers, earnings)
    actual = {
        (shareholder, db.dividends(shareholder))
        for shareholder in shareholders
    }
    assert expected == actual
