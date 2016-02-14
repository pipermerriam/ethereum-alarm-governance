import pytest


deploy_contracts = []


ONE_DAY = 24 * 60 * 60


@pytest.mark.parametrize(
    "quorium,pass_percentage,debate_period,executor,expected",
    (
        (10000, 51, ONE_DAY, "0xd3cda913deb6f67967b99d67acdfa1712c293601", True),
        (10001, 51, ONE_DAY, "0xd3cda913deb6f67967b99d67acdfa1712c293601", True),
        (10000, 100, ONE_DAY, "0xd3cda913deb6f67967b99d67acdfa1712c293601", True),
        (10000, 100, ONE_DAY + 1, "0xd3cda913deb6f67967b99d67acdfa1712c293601", True),
        (9999, 100, ONE_DAY, "0xd3cda913deb6f67967b99d67acdfa1712c293601", False),
        (10000, 50, ONE_DAY, "0xd3cda913deb6f67967b99d67acdfa1712c293601", False),
        (10000, 51, ONE_DAY - 1, "0xd3cda913deb6f67967b99d67acdfa1712c293601", False),
        (10000, 51, ONE_DAY, "0x0000000000000000000000000000000000000000", False),
    )
)
def test_validation_with_acceptable_values(deploy_contract, contracts,
                                           deploy_client, accounts,
                                           get_log_data, deploy_coinbase,
                                           Status, quorium, debate_period,
                                           pass_percentage, executor,
                                           expected):
    validator = deploy_contract(contracts.Validator)

    validator.setMinimumQuorum.s(10000)
    validator.setMinimumPassPercentage.s(51)
    validator.setMinimumDebatePeriod.s(ONE_DAY)

    motion = deploy_contract(
        contracts.Motion,
        constructor_args=(deploy_coinbase,),
    )
    motion.configure.s(quorium, debate_period, pass_percentage, executor)

    actual = validator.validate(motion._meta.address)
    assert actual is expected
