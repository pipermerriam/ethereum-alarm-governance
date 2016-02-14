import {ShareholderDBInterface} from "contracts/ShareholderDB.sol";
import {transferableInterface, transferable} from "contracts/owned.sol";


contract ShareholderDBSubscriber {
    function getShareholderDB() constant returns (address);

    modifier onlyshareholder {
        if (!ShareholderDBInterface(getShareholderDB()).isShareholder(msg.sender)) throw; _
    }
}


contract DelegatedShareholderDBSubscriber is transferableInterface, ShareholderDBSubscriber {
    function getShareholderDB() constant returns (address) {
        return ShareholderDBSubscriber(owner).getShareholderDB();
    }
}
