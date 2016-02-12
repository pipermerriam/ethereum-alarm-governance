import pytest


@pytest.fixture
def deploy_contract(deploy_client, contracts):
    from populus.deployment import (
        deploy_contracts,
    )

    def _deploy_contract(ContractClass, constructor_args=None):
        if constructor_args is not None:
            constructor_args = {
                ContractClass.__name__: constructor_args,
            }
        deployed_contracts = deploy_contracts(
            deploy_client=deploy_client,
            contracts=contracts,
            contracts_to_deploy=[ContractClass.__name__],
            constructor_args=constructor_args,
        )

        contract = getattr(deployed_contracts, ContractClass.__name__)
        assert deploy_client.get_code(contract._meta.address)
        return contract
    return _deploy_contract

@pytest.fixture
def py_dividends():
    import decimal
    import time
    import itertools
    import collections
    import random


    deploy_contracts = []


    def balance_at(when, history, current):
        if not history:
            return current

        for idx, balance in history:
            if when <= idx:
                return balance

        return current


    def process_transfers(init_balances, transfers):
        ledger = collections.defaultdict(list)
        balances = collections.defaultdict(int)

        balances.update(dict(init_balances))

        for acct, balance in init_balances:
            ledger[acct].append((0, balance))

        for when, _from, to, value in transfers:
            if balances[_from] < value:
                raise ValueError("Insufficient balance")

            ledger[_from].append((when, balances[_from]))
            ledger[to].append((when, balances[to]))

            balances[_from] -= value
            balances[to] += value

        return dict(balances), dict(ledger)


    def compute_dividends(balances, ledger, earnings):
        dividends = collections.defaultdict(int)

        total_supply = sum(balances.values())

        for when, value in earnings:
            for acct in ledger.keys():
                bal = balance_at(when, ledger[acct], balances[acct])
                dividends[acct] += bal * value
                #print "{when}: {acct} > +{bal}".format(when=when, acct=acct, bal=bal)
        return dict(dividends.items())

    return type('py_dividends', (object,), {
        'balance_at': staticmethod(balance_at),
        'compute_dividends': staticmethod(compute_dividends),
        'process_transfers': staticmethod(process_transfers),
    })


@pytest.fixture
def get_log_data(deploy_client, contracts):
    def _get_log_data(event, txn_hash, indexed=True):
        event_logs = event.get_transaction_logs(txn_hash)
        assert len(event_logs)

        if len(event_logs) == 1:
            event_data = event.get_log_data(event_logs[0], indexed=indexed)
        else:
            event_data = tuple(
                event.get_log_data(l, indexed=indexed) for l in event_logs
            )
        return event_data
    return _get_log_data
