import pytest

from ethereum.tester import TransactionFailed


deploy_contracts = []


def test_accepting_motion_advances_status(deploy_contract, contracts,
                                          deploy_client, accounts,
                                          get_log_data, deploy_coinbase,
                                          Status):
    motion = deploy_contract(
        contracts.Motion,
        constructor_args=(deploy_coinbase,),
    )

    motion.configure(40, 60 * 60 * 24 * 7, 51, accounts[1])

    assert motion.status() == Status.NeedsValidation

    motion.accept.s()

    assert motion.status() == Status.Open


def test_rejecting_reverts_to_needing_configuration(deploy_contract, contracts,
                                                    deploy_client, accounts,
                                                    get_log_data,
                                                    deploy_coinbase, Status):
    motion = deploy_contract(
        contracts.Motion,
        constructor_args=(deploy_coinbase,),
    )

    motion.configure(40, 60 * 60 * 24 * 7, 51, accounts[1])

    assert motion.status() == Status.NeedsValidation

    motion.reject.s()

    assert motion.status() == Status.NeedsConfiguration


def test_accept_and_reject_restricted_to_owner(deploy_contract, contracts,
                                               deploy_client, accounts,
                                               get_log_data, deploy_coinbase,
                                               Status):
    motion = deploy_contract(
        contracts.Motion,
        constructor_args=(deploy_coinbase,),
    )

    motion.configure(40, 60 * 60 * 24 * 7, 51, accounts[1])

    assert motion.status() == Status.NeedsValidation

    with pytest.raises(TransactionFailed):
        motion.reject.s(_from=accounts[1])

    assert motion.status() == Status.NeedsValidation

    with pytest.raises(TransactionFailed):
        motion.accept.s(_from=accounts[1])

    assert motion.status() == Status.NeedsValidation
