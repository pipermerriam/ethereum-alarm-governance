import {ShareholderDB} from "contracts/ShareholderDB.sol";
import {DividendDBInterface, DividendDBBase} from "contracts/DividendDB.sol";
import {ERC20} from "contracts/ERC20.sol";


contract MillionSharesDB is ShareholderDB(1000000) {
    function setDividendsDB(address _address) {
        dividendsDB = DividendDBInterface(_address);
    }
}


contract DividendsDBTest is DividendDBBase {
    function setToken(address _address) {
        token = ERC20(_address);
    }
}


contract ShareholderDBOwner {
    address shareholderDB;

    function setShareholderDB(address _address) public {
        shareholderDB = _address;
    }

    function getShareholderDB() constant returns (address) {
        return shareholderDB;
    }
}


contract CallDataLogger {
    bool public wasCalled;
    address public msgSender;
    bytes public data;
    uint public value;
    uint public gas;

    function() public {
        gas = msg.gas;
        value = msg.value;
        msgSender = msg.sender;
        data = msg.data;
        wasCalled = true;
    }

    function reset() public {
        gas = 0;
        value = 0;
        msgSender = 0x0;
        data.length = 0;
        wasCalled = false;
    }
}
