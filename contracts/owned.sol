contract owned {
    function owned() {
        owner = msg.sender;
    }

    address public owner;

    modifier onlyowner { if (msg.sender != owner) throw; _ }
}
