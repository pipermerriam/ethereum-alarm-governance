deploy_contracts = []


def test_total_supply(deploy_contract, contracts):
    token = deploy_contract(contracts.MillionSharesDB)

    assert token.totalSupply() == 1000000
