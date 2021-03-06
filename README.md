# Ethereum Alarm Governance

A democratic framework for governance of the Ethereum Alarm Clock service.


## What is this?

While the Alarm Service will always remain trustless with no special access
granted to any entity, there are things that fit well under the DAO style of
governance.

- Allocation of the fees that are generated by the service.
- Management of a separate reputation service.
- Updating a contract resolver address with the latest address of the service.


## Status

Not in any way ready for public consumption.


## Components

- ShareholderDB - ERC20 compliant token system to be used as Shares.
- DividendDB    - Handle dividends allocation based on shares.
- Govenor       - Proxy Contract that "owns" stuff
- Boardroom     - Democratic voting to direct the actions of the Govenor contract.
- Motion        - A piece of on-chain logic that can execute actions through the Govenor.
