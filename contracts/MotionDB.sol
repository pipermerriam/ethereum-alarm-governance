import {GroveLib} from "libraries/GroveLib.sol";
import {transferableInterface, transferable, ownerType, owner} from "contracts/owned.sol";
import {MotionInterface} from "contracts/Motion.sol";
import {FactoryInterface} from "contracts/Factory.sol";
import {ValidatorInterface} from "contracts/Validator.sol";
import {ShareholderDBInterface} from "contracts/ShareholderDB.sol";


contract MotionDBInterface is transferableInterface, ownerType {
    using GroveLib for GroveLib.Index;

    FactoryInterface public factory;
    ValidatorInterface public validator;
    ShareholderDBInterface public shareholderDB;

    GroveLib.Index motions;

    modifier onlyshareholder { 
        if (address(shareholderDB) == 0x0) throw;
        if (shareholderDB.isShareholder(msg.sender)) {
            _
        }
        else {
            throw;
        }
    }

    function add(address _address) public onlyowner;
    function remove(address _address) public onlyowner;
    function exists(address _address) constant returns (bool);
    function create() public onlyshareholder;
    function validate(address _address) public onlyshareholder;
}


contract MotionDB is transferable, owner, MotionDBInterface {
    /*
     *  Factory Management
     */
    function setFactory(address _address) public onlyowner {
        factory = FactoryInterface(_address);
    }

    /*
     *  Validator Management
     */
    function setValidator(address _address) public onlyowner {
        validator = ValidatorInterface(_address);
    }

    /*
     *  ShareholderDB Management
     */
    function setShareholderDB(address _address) public onlyowner {
        shareholderDB = ShareholderDBInterface(_address);
    }

    /*
     *  Main API
     */
    function create() public onlyshareholder {
        var motion = factory.deployContract(msg.sender);
        motions.insert(bytes32(motion), int(block.number));
    }

    function add(address _address) public onlyowner {
        motions.insert(bytes32(_address), int(block.number));
    }

    function remove(address _address) public onlyowner {
        motions.remove(bytes32(_address));
    }

    function exists(address _address) constant returns (bool) {
        return motions.exists(bytes32(_address));
    }

    function validate(address _address) public onlyshareholder {
        if (!motions.exists(bytes32(_address))) throw;

        var motion = MotionInterface(_address);

        if (validator.validate(_address)) {
            motion.accept();
        }
        else {
            motion.reject();
        }
    }
}
