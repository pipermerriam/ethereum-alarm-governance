import {MotionDBInterface} from "contracts/MotionDB.sol";


contract MotionDBSubscriber {
    function getMotionDB() constant returns (address);

    modifier onlymotion {
        if (!MotionDBInterface(getMotionDB()).exists(msg.sender)) throw; _
    }
}
