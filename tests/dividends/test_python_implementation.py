deploy_contracts = []


def test_processing_transfers(py_dividends):
    supply = 1000000
    init_balances = (
        ('A', supply),
    )
    transfers = (
        (1, 'A', 'B', 400000),
        (2, 'A', 'C', 100000),
        (3, 'B', 'C', 100000),
    )

    balances, ledger = py_dividends.process_transfers(init_balances, transfers)

    assert balances['A'] == 500000
    assert balances['B'] == 300000
    assert balances['C'] == 200000

    assert py_dividends.balance_at(0, ledger['A'], balances['A']) == 1000000
    assert py_dividends.balance_at(1, ledger['A'], balances['A']) == 1000000
    assert py_dividends.balance_at(2, ledger['A'], balances['A']) == 600000
    assert py_dividends.balance_at(3, ledger['A'], balances['A']) == 500000
    assert py_dividends.balance_at(4, ledger['A'], balances['A']) == 500000

    assert py_dividends.balance_at(0, ledger['B'], balances['B']) == 0
    assert py_dividends.balance_at(1, ledger['B'], balances['B']) == 0
    assert py_dividends.balance_at(2, ledger['B'], balances['B']) == 400000
    assert py_dividends.balance_at(3, ledger['B'], balances['B']) == 400000
    assert py_dividends.balance_at(4, ledger['B'], balances['B']) == 300000
    assert py_dividends.balance_at(5, ledger['B'], balances['B']) == 300000

    assert py_dividends.balance_at(0, ledger['C'], balances['C']) == 0
    assert py_dividends.balance_at(1, ledger['C'], balances['C']) == 0
    assert py_dividends.balance_at(2, ledger['C'], balances['C']) == 0
    assert py_dividends.balance_at(3, ledger['C'], balances['C']) == 100000
    assert py_dividends.balance_at(4, ledger['C'], balances['C']) == 200000
    assert py_dividends.balance_at(5, ledger['C'], balances['C']) == 200000


def test_simple_dividends_computation(py_dividends):
    # balances are in the format (who, initial_balance)
    supply = 1000000
    init_balances = (
        ('A', supply),
    )
    # earnings are earnings in the format (when, how_much)
    earnings = (
        (1, 100),
        (3, 100),
        (5, 100),
        (7, 100),
        (8, 100),
    )

    # transfers are in the format (when, from, to, value)
    transfers = (
        (2, 'A', 'B', 400000),
        (4, 'A', 'C', 100000),
        (6, 'B', 'C', 100000),
    )

    balances, ledger = py_dividends.process_transfers(init_balances, transfers)
    actual = py_dividends.compute_dividends(balances, ledger, earnings)

    expected = dict((
        ('A', (100 + 60 + 50 * 3) * supply),
        ('B', (40 * 2 + 30 * 2) * supply),
        ('C', (10 + 20 * 2) * supply),
    ))

    assert actual == expected


def test_complex_dividends(py_dividends):
    supply = 1000000
    init_balances = (
        ('A', supply),
    )
    transfers = (
        (2, 'A', 'B', 100000),
        (4, 'A', 'B', 100000),
        (7, 'B', 'C', 100000),
    )

    earnings = (
        (1, 100),
        (3, 100),
        (5, 100),
        (6, 100),
    )

    balances, ledger = py_dividends.process_transfers(init_balances, transfers)

    assert balances['A'] == 800000
    assert balances['B'] == 100000
    assert balances['C'] == 100000

    actual = py_dividends.compute_dividends(balances, ledger, earnings)

    expected = dict((
        ('A', (100 + 90 + 80 * 2) * supply),
        ('B', (10 + 20 * 2) * supply),
        ('C', (0) * supply),
    ))
