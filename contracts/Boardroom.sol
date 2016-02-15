import {transferableInterface, transferable} from "contracts/owned.sol";
import {ProxyInterface, Proxy} from "contracts/Proxy.sol";
import {ShareholderDBInterface} from "contracts/ShareholderDB.sol";
import {ShareholderDBSubscriber} from "contracts/ShareholderDBSubscriber.sol";
import {DividendDBSubscriber} from "contracts/DividendDBSubscriber.sol";
import {MotionDBSubscriber} from "contracts/MotionDBSubscriber.sol";
import {DividendDBInterface} from "contracts/ShareholderDB.sol";
import {MotionDBInterface} from "contracts/MotionDB.sol";


contract BoardroomInterface is ProxyInterface, ShareholderDBSubscriber, MotionDBSubscriber, DividendDBSubscriber {
    ShareholderDBInterface public shareholderDB;
    DividendDBInterface public dividendsDB;
    MotionDBInterface public motionDB;

    /*
     * These are technically executable via the ProxyInterface but they exist
     * as conveninece functions for other contracts to use if they need the
     * interface.
     */
    function setShareholderDB(address _address) public onlyowner;
    function transferShareholderDB(address newOwner) public onlyowner;
    function setDividendDB(address _address) public onlyowner;
    function transferDividendDB(address newOwner) public onlyowner;
    function setMotionDB(address _address) public onlyowner;
    function transferMotionDB(address newOwner) public onlyowner;
}


contract Boardroom is transferable, Proxy, BoardroomInterface {
    /*
     *  Database management
     */
    function setShareholderDB(address _address) public onlyowner {
        shareholderDB = ShareholderDBInterface(_address);
    }

    function transferShareholderDB(address newOwner) public onlyowner {
        shareholderDB.transferOwnership(newOwner);
    }

    function getShareholderDB() constant returns (address) {
        return shareholderDB;
    }

    function setDividendDB(address _address) public onlyowner {
        dividendsDB = DividendDBInterface(_address);
    }

    function transferDividendDB(address newOwner) public onlyowner {
        dividendsDB.transferOwnership(newOwner);
    }

    function getDividendDB() constant returns (address) {
        return dividendsDB;
    }

    function setMotionDB(address _address) public onlyowner {
        motionDB = MotionDBInterface(_address);
    }

    function getMotionDB() constant returns (address) {
        return motionDB;
    }

    function transferMotionDB(address newOwner) public onlyowner {
        motionDB.transferOwnership(newOwner);
    }

    function __proxy_motion(address to, uint value, uint gas, bytes callData) public onlymotion  returns (bool) {
        return ____forward(to, value, gas, callData);
    }
}
