contract GovenorInterface {
    address public owner;

    event OwnershipTransfer(address oldOwner, address newOwner);

    struct Action {
        uint id;
        address owner;
        address to;
        bytes callData;
        uint value;
        uint gas;
        bool wasSuccessful;
    }

    modifier onlyowner { if (msg.sender != owner) throw; _ }

    function __forward(address to, bytes callData, uint value, uint gas) onlyowner returns (bool);
    function transfer_owner(address new_owner) onlyowner;
}


contract Govenor is GovenorInterface {
    function Govenor() {
        owner = msg.sender;
    }

    uint id;
    mapping (uint => Action) public actions;

    function __forward(address to, bytes callData, uint value, uint gas) onlyowner returns (bool) {
        id += 1;

        var action = actions[id];
        action.owner = owner;
        action.to = to;
        action.callData = callData;
        action.value = value;
        action.gas = gas;

        if (gas > 0 && value > 0) {
            action.wasSuccessful = to.call.gas(gas).value(value)(callData);
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

    function transfer_owner(address new_owner) onlyowner {
        OwnershipTransfer(owner, new_owner);
        owner = new_owner;
    }

    function () {
        // Fallback to allow receipt of ether.
    }
}
