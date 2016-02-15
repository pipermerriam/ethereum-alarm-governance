import {transferableInterface, transferable, ownerType, owner} from "contracts/owned.sol";
import {ProxyInterface, Proxy} from "contracts/Proxy.sol";
import {ShareholderDBInterface} from "contracts/ShareholderDB.sol";
import {DividendDBInterface} from "contracts/ShareholderDB.sol";
import {MotionDBInterface} from "contracts/MotionDB.sol";


contract BoardroomInterface is transferableInterface, ownerType, ProxyInterface {
    ShareholderDBInterface public shareholderDB;
    DividendDBInterface public dividendsDB;
    MotionDBInterface public motionDB;

    modifier onlymotion { if (!motionDB.exists(msg.sender)) throw; _ }

    /*
     * These are technically executable via the ProxyInterface but they exist
     * as conveninece functions for other contracts to use if they need the
     * interface.
     */
    function setShareholderDB(address _address) public onlyowner;
    function setDividendDB(address _address) public onlyowner;
    function setMotionDB(address _address) public onlyowner;
}


contract Boardroom is transferable, owner, Proxy, BoardroomInterface {
    /*
     *  Database management
     */
    function setShareholderDB(address _address) public onlyowner {
        shareholderDB = ShareholderDBInterface(_address);
    }

    function setDividendDB(address _address) public onlyowner {
        dividendsDB = DividendDBInterface(_address);
    }

    function setMotionDB(address _address) public onlyowner {
        motionDB = MotionDBInterface(_address);
    }

    function __proxy_motion(address to, uint value, uint gas, bytes callData) public onlymotion  returns (bool) {
        // TODO: need to check if it has passed.
        return ____forward(to, value, gas, callData);
    }
}
