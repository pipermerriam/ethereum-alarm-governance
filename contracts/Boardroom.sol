import "libraries/GroveLib.sol";

import {transferableInterface, transferable} from "contracts/owned.sol";
import {ProxyInterface} from "contracts/Proxy.sol";
import {ShareholderDBInterface} from "contracts/ShareholderDB.sol";
import {DividendDBInterface} from "contracts/ShareholderDB.sol";
import {ValidatorInterface} from "contracts/Validator.sol";
import {FactoryInterface} from "contracts/Factory.sol";
import {MotionInterface} from "contracts/Motion.sol";


contract BoardroomInterface is ProxyInterface {
    ShareholderDBInterface public shareholderDB;
    DividendDBInterface public dividendsDB;
    FactoryInterface public factory;
    ValidatorInterface public validator;

    function setMinimumDebateDuration(uint duration) public onlyowner;
    function getMinimumDebateDuration(uint duration) constant returns (uint);

    function setShareholderDB(address _address) public onlyowner;
    function setDividendDB(address _address) public onlyowner;

    modifier onlyshareholder { if (!shareholderDB.isShareholder(msg.sender)) throw; _ }
    modifier onlyfactory { if (msg.sender != address(factory)) throw; _ }

    event MotionCreated(address motion);
}


contract Boardroom is transferable, BoardroomInterface {
    using GroveLib for GroveLib.Index;

    /*
     *  Database management
     */
    function setShareholderDB(address _address) public onlyowner {
        shareholderDB = ShareholderDBInterface(_address);
    }

    function setDividendDB(address _address) public onlyowner {
        dividendsDB = DividendDBInterface(_address);
    }

    function setFactory(address _address) public onlyowner {
        factory = FactoryInterface(_address);
    }

    GroveLib.Index motions;

    function isKnownMotion(address _address) constant returns (bool) {
        return motions.exists(bytes32(_address));
    }

    function createMotion(address _address) public onlyfactory {
        var motion = factory.buildMotionContract(msg.sender, _address);
        motions.insert(bytes32(motion), int(block.number));
    }

    function validateMotion(address _address) public onlyshareholder {
        if (!motions.exists(bytes32(_address))) throw;

        var motion = MotionInterface(_address);

        if (validator.validateMotion(_address)) {
            motion.accept();
        }
        else {
            motion.reject();
        }
    }

    function __proxy_motion(bytes call_data) public {
        // TODO: allow motions to execute through this function.
    }
}
