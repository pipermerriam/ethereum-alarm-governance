import {GroveLib} from "libraries/GroveLib.sol";
import {transferableInterface, transferable} from "contracts/owned.sol";
import {MotionInterface} from "contracts/Motion.sol";
import {FactoryInterface} from "contracts/Factory.sol";
import {ShareholderDBSubscriber} from "contracts/ShareholderDBSubscriber.sol";
import {ValidatorInterface} from "contracts/Validator.sol";


contract MotionDBInterface is transferableInterface, ShareholderDBSubscriber {
    using GroveLib for GroveLib.Index;

    FactoryInterface public factory;
    ValidatorInterface public validator;

    GroveLib.Index motions;

    function add(address _address) public onlyowner;
    function remove(address _address) public onlyowner;
    function exists(address _address) constant returns (bool);
    function create(address _address) public onlyowner;
    function validate(address _address) public onlyshareholder;
}


contract MotionDB is transferable, MotionDBInterface {
    /*
     *  ShareholderDBSubscriber
     */
    function getShareholderDB() constant returns (address) {
        return ShareholderDBSubscriber(owner).getShareholderDB();
    }

    /*
     *  Factory Management
     */
    function setFactory(address _address) public onlyowner {
        factory = FactoryInterface(_address);
    }

    function transferFactory(address newOwner) public onlyowner {
        factory.transferOwnership(newOwner);
    }

    /*
     *  Validator Management
     */
    function setValidator(address _address) public onlyowner {
        validator = ValidatorInterface(_address);
    }

    function transferValidator(address newOwner) public onlyowner {
        validator.transferOwnership(newOwner);
    }

    /*
     *  Main API
     */
    function create(address _address) public onlyshareholder {
        var motion = factory.deployContract(msg.sender, _address);
        add(motion);
    }

    function add(address _address) public onlyowner {
        motions.insert(bytes32(_address), int(block.number));
    }

    function remove(address _address) public onlyowner {
        motions.remove(bytes32(_address));
    }

    function transfer(address _address, address newOwner) public onlyowner {
        if (!exists(_address)) throw;
        var motion = MotionInterface(_address);
        motion.transferOwnership(newOwner);
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
