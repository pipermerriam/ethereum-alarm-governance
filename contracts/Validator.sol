import {transferableInterface, transferable} from "contracts/owned.sol";
import {MotionInterface} from "contracts/Motion.sol";


contract ValidatorInterface is transferableInterface {
    uint minimumQuorum;
    uint minimumDuration;
    uint minimumPassPercentage;

    function setMinimumQuorum(uint value) public onlyowner;
    function setMinimumDuration(uint value) public onlyowner;
    function setMinimumPassPercentage(uint value) public onlyowner;
    function validateMotion(address _address) constant returns (bool);
}


contract Validator is transferable, ValidatorInterface {
    uint minimumQuorum;
    uint minimumDuration;
    uint minimumPassPercentage;

    function setMinimumQuorum(uint value) public onlyowner {
        minimumQuorum = value;
    }

    function setMinimumDuration(uint value) public onlyowner {
        minimumDuration = value;
    }

    function setMinimumPassPercentage(uint value) public onlyowner {
        minimumPassPercentage = value;
    }

    function validateMotion(address _address) constant returns (bool) {
        var motion = MotionInterface(_address);

        if (motion.quorumSize() < minimumQuorum) return false;
        if (motion.duration() < minimumDuration) return false;
        if (motion.passPercentage() < minimumPassPercentage) return false;

        return true;
    }
}
