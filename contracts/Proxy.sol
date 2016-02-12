import {transferableInterface, transferable} from "contracts/owned.sol";


contract ProxyInterface is transferableInterface {
    struct Action {
        uint id;
        address owner;
        address to;
        bytes callData;
        uint value;
        uint gas;
        bool wasSuccessful;
    }

    function ____forward(address to, uint value, uint gas, bytes callData) internal returns (bool);
    function __forward(address to, uint value, uint gas, bytes callData) onlyowner returns (bool);
}


contract Proxy is transferable, ProxyInterface {
    function Proxy() {
        owner = msg.sender;
    }

    uint public numActions;
    mapping (uint => Action) public actions;

    function ____forward(address to, uint value, uint gas, bytes callData) internal returns (bool) {
        numActions += 1;

        var action = actions[numActions];
        action.id = numActions;
        action.owner = owner;
        action.to = to;
        action.callData = callData;
        action.value = value;
        action.gas = gas;

        if (gas > 0 && value > 0) {
            action.wasSuccessful = to.call.value(value).gas(gas)(callData);
        }
        else if (value > 0) {
            action.wasSuccessful = to.call.value(value)(callData);
        }
        else if (gas > 0) {
            action.wasSuccessful = to.call.gas(gas)(callData);
        }
        else {
            action.wasSuccessful = to.call(callData);
        }

        return action.wasSuccessful;
    }

    function __forward(address to, uint value, uint gas, bytes callData) onlyowner returns (bool) {
        return ____forward(to, value, gas, callData);
    }

    function () {
        // Fallback to allow receipt of ether.
    }
}
