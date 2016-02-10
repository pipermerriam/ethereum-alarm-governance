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
