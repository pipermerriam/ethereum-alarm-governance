import pytest


@pytest.fixture
def deploy_contract(deploy_client, contracts):
    from populus.deployment import (
        deploy_contracts,
    )

    def _deploy_contract(ContractClass, constructor_args=None, from_address=None):
        if constructor_args is not None:
            constructor_args = {
                ContractClass.__name__: constructor_args,
            }
        deployed_contracts = deploy_contracts(
            deploy_client=deploy_client,
            contracts=contracts,
            contracts_to_deploy=[ContractClass.__name__],
            constructor_args=constructor_args,
            from_address=None,
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


@pytest.fixture
def Status():
    values = {
        'NeedsConfiguration': 0,
        'NeedsValidation': 1,
        'Open': 2,
        'Tally': 3,
        'Passed': 4,
        'Failed': 5,
        'Executing': 6,
        'Executed': 7,
    }
    return type("Status", (object,), values)


@pytest.fixture
def deploy_constellation(deploy_contract, contracts, deploy_coinbase):
    def _deploy_constellation(dao_operator=deploy_coinbase,
                              additional_shareholders=None,
                              validation_minimums=None):
        boardroom = deploy_contract(contracts.Boardroom, from_address=dao_operator)

        shareholder_db = deploy_contract(
            contracts.ShareholderDB,
            constructor_args=(1000000,),
            from_address=dao_operator,
        )
        dividend_db = deploy_contract(contracts.DividendDBTest, from_address=dao_operator)
        shareholder_db.addShareholder.s(dao_operator)
        if additional_shareholders is not None:
            for sh in additional_shareholders:
                shareholder_db.addShareholder.s(sh)

        shareholder_db.transferOwnership.s(boardroom._meta.address, _from=dao_operator)
        boardroom.setShareholderDB.s(shareholder_db._meta.address, _from=dao_operator)

        dividend_db.transferOwnership.s(boardroom._meta.address, _from=dao_operator)
        boardroom.setDividendDB.s(dividend_db._meta.address, _from=dao_operator)

        motion_db = deploy_contract(contracts.MotionDB, from_address=dao_operator)
        validator = deploy_contract(contracts.Validator, from_address=dao_operator)
        factory = deploy_contract(
            contracts.MotionFactory,
            constructor_args=("ipfs://example", "1.2.3", "--example"),
            from_address=dao_operator,
        )

        if validation_minimums is not None:
            quorum_size = validation_minimums.get('quorum_size')
            debate_period = validation_minimums.get('debate_period')
            pass_percentage = validation_minimums.get('pass_percentage')

            if quorum_size is not None:
                validator.setMinimumQuorum.s(quorum_size)

            if debate_period is not None:
                validator.setMinimumDebatePeriod.s(debate_period)

            if pass_percentage is not None:
                validator.setMinimumPassPercentage.s(pass_percentage)

        motion_db.setShareholderDB(shareholder_db._meta.address)

        validator.transferOwnership.s(motion_db._meta.address, _from=dao_operator)
        motion_db.setValidator.s(validator._meta.address, _from=dao_operator)

        factory.transferOwnership.s(motion_db._meta.address, _from=dao_operator)
        motion_db.setFactory.s(factory._meta.address, _from=dao_operator)

        motion_db.transferOwnership.s(boardroom._meta.address, _from=dao_operator)
        boardroom.setMotionDB.s(motion_db._meta.address, _from=dao_operator)

        # sanity checks
        assert validator.owner() == motion_db._meta.address
        assert factory.owner() == motion_db._meta.address
        assert motion_db.owner() == boardroom._meta.address
        assert motion_db.shareholderDB() == shareholder_db._meta.address
        assert shareholder_db.owner() == boardroom._meta.address
        assert dividend_db.owner() == boardroom._meta.address

        values = {
            'shareholder_db': shareholder_db,
            'dividend_db': dividend_db,
            'motion_db': motion_db,
            'validator': validator,
            'factory': factory,
            'boardroom': boardroom,
        }
        return type("constellation", (object,), values)
    return _deploy_constellation
