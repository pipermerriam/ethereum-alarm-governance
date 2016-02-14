import {transferableInterface, transferable} from "contracts/owned.sol";
import {MotionInterface} from "contracts/Motion.sol";


contract ValidatorInterface is transferableInterface {
    uint public minimumQuorum;
    uint public minimumDebatePeriod;
    uint8 public minimumPassPercentage;

    function setMinimumQuorum(uint value) public onlyowner;
    function setMinimumDebatePeriod(uint value) public onlyowner;
    function setMinimumPassPercentage(uint8 value) public onlyowner;
    function validate(address _address) constant returns (bool);
}


contract Validator is transferable, ValidatorInterface {
    function setMinimumQuorum(uint value) public onlyowner {
        minimumQuorum = value;
    }

    function setMinimumDebatePeriod(uint value) public onlyowner {
        minimumDebatePeriod = value;
    }

    function setMinimumPassPercentage(uint8 value) public onlyowner {
        if (value >= 100) throw;
        minimumPassPercentage = value;
    }

    function validate(address _address) constant returns (bool) {
        var motion = MotionInterface(_address);

        if (motion.quorumSize() < minimumQuorum) return false;
        if (motion.duration() < minimumDebatePeriod) return false;
        if (motion.passPercentage() < minimumPassPercentage) return false;
        if (address(motion.executable()) == 0x0) return false;

        return true;
    }
}
