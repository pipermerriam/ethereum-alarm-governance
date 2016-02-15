import {transferableInterface, transferable} from "contracts/owned.sol";


contract DividendDBSubscriber {
    function getDividendDB() constant returns (address);

    modifier onlydividend_db {
        if (msg.sender != getDividendDB()) throw; _
    }
}
