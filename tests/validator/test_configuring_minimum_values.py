import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_configuring_quorum_minimum(deploy_contract, contracts, deploy_client,
                                    accounts, get_log_data, deploy_coinbase,
                                    Status):
    validator = deploy_contract(contracts.Validator)

    assert validator.minimumQuorum() == 0

    validator.setMinimumQuorum.s(12345)

    assert validator.minimumQuorum() == 12345

    validator.setMinimumQuorum.s(54321)

    assert validator.minimumQuorum() == 54321


def test_only_owner_can_set_quorum(deploy_contract, contracts, deploy_client,
                                   accounts, get_log_data, deploy_coinbase,
                                   Status):
    validator = deploy_contract(contracts.Validator)

    assert validator.minimumQuorum() == 0

    with pytest.raises(TransactionFailed):
        validator.setMinimumQuorum.s(12345, _from=accounts[1])

    assert validator.minimumQuorum() == 0


def test_configuring_debate_period_minimum(deploy_contract, contracts,
                                           deploy_client, accounts,
                                           get_log_data, deploy_coinbase,
                                           Status):
    validator = deploy_contract(contracts.Validator)

    assert validator.minimumDebatePeriod() == 0

    validator.setMinimumDebatePeriod.s(12345)

    assert validator.minimumDebatePeriod() == 12345

    validator.setMinimumDebatePeriod.s(54321)

    assert validator.minimumDebatePeriod() == 54321


def test_only_owner_can_set_debate_period_contract(deploy_contract, contracts,
                                                   deploy_client, accounts,
                                                   get_log_data,
                                                   deploy_coinbase, Status):
    validator = deploy_contract(contracts.Validator)

    assert validator.minimumDebatePeriod() == 0

    with pytest.raises(TransactionFailed):
        validator.setMinimumDebatePeriod.s(12345, _from=accounts[1])

    assert validator.minimumDebatePeriod() == 0


def test_configuring_pass_percentage_minimum(deploy_contract, contracts,
                                             deploy_client, accounts,
                                             get_log_data, deploy_coinbase,
                                             Status):
    validator = deploy_contract(contracts.Validator)

    assert validator.minimumPassPercentage() == 0

    validator.setMinimumPassPercentage.s(51)

    assert validator.minimumPassPercentage() == 51

    validator.setMinimumPassPercentage.s(60)

    assert validator.minimumPassPercentage() == 60


def test_only_owner_can_set_pass_percentage_contract(deploy_contract,
                                                     contracts, deploy_client,
                                                     accounts, get_log_data,
                                                     deploy_coinbase, Status):
    validator = deploy_contract(contracts.Validator)

    assert validator.minimumPassPercentage() == 0

    with pytest.raises(TransactionFailed):
        validator.setMinimumPassPercentage.s(51, _from=accounts[1])

    assert validator.minimumPassPercentage() == 0


def test_pass_percentage_must_be_less_than_100(deploy_contract, contracts,
                                               deploy_client, accounts,
                                               get_log_data, deploy_coinbase,
                                               Status):
    validator = deploy_contract(contracts.Validator)

    assert validator.minimumPassPercentage() == 0

    with pytest.raises(TransactionFailed):
        validator.setMinimumPassPercentage.s(100)

    assert validator.minimumPassPercentage() == 0

    with pytest.raises(TransactionFailed):
        validator.setMinimumPassPercentage.s(101)

    assert validator.minimumPassPercentage() == 0

    validator.setMinimumPassPercentage.s(99)

    assert validator.minimumPassPercentage() == 99
