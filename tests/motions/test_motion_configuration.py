import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_motion_creator_can_canfigure_motion(deploy_contract, contracts,
                                             deploy_client, accounts,
                                             get_log_data, deploy_coinbase,
                                             Status):
    motion = deploy_contract(
        contracts.Motion,
        constructor_args=(deploy_coinbase,),
    )

    assert motion.status() == Status.NeedsConfiguration


def test_motion_restricts_configuration_to_creator(deploy_contract, contracts,
                                                   deploy_client, accounts,
                                                   get_log_data,
                                                   deploy_coinbase, Status):
    motion = deploy_contract(
        contracts.Motion,
        constructor_args=(deploy_coinbase,),
    )

    assert motion.createdBy() == deploy_coinbase
    assert motion.status() == Status.NeedsConfiguration

    with pytest.raises(TransactionFailed):
        motion.configure(
            40, 60 * 60 * 24 * 7, 51, accounts[1],
            _from=accounts[1],
        )

    assert motion.status() == Status.NeedsConfiguration

def test_motion_configuration(deploy_contract, contracts, deploy_client,
                              accounts, get_log_data, deploy_coinbase, Status):
    motion = deploy_contract(
        contracts.Motion,
        constructor_args=(deploy_coinbase,),
    )

    assert motion.createdBy() == deploy_coinbase
    assert motion.status() == Status.NeedsConfiguration

    motion.configure(40, 60 * 60 * 24 * 7, 51, accounts[1])

    assert motion.status() == Status.NeedsValidation
    assert motion.executable() == accounts[1]
    assert motion.quorumSize() == 40
    assert motion.duration() == 60 * 60 * 24 * 7
    assert motion.passPercentage() == 51
