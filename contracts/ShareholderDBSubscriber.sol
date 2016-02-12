import {ShareholderDBInterface} from "contracts/ShareholderDB.sol";


contract ShareholderDBSubscriber {
    function getShareholderDB() constant returns (address);

    modifier onlyshareholder {
        if (!ShareholderDBInterface(getShareholderDB()).isShareholder(msg.sender)) throw; _
    }
}
