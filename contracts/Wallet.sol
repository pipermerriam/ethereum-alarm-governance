import {transferableInterface, transferable} from "contracts/owned.sol";
import {ERC20} from "contracts/ERC20.sol";


contract WalletType is transferableInterface, ERC20 {
    event Deposit(address indexed from, address indexed to, uint value);
    event Withdrawl(address indexed by, address indexed to, uint value);

    function deposit(address to) public returns (bool ok);
    function withdraw(address to, uint value) public returns (bool ok);
    function withdrawFrom(address from, address to, uint value) returns (bool ok);
}


contract Wallet is transferable, WalletType {
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;

    /*
     *  Utility
     */
    function sendRobust(address to, uint value) internal {
        if (!to.send(value)) {
            if (!to.call.value(value)()) throw;
        }
    }

    /*
     *  Withdrawl and Deposit
     */
    function deposit(address to) public returns (bool ok) {
        if (msg.value == 0) return false;

        balances[to] += msg.value;
        Deposit(msg.sender, to, msg.value);

        return true;
    }

    function () {
        deposit(owner);
    }

    function withdraw(address to, uint value) public returns (bool ok) {
        if (balances[msg.sender] < value) return false;
        if (value == 0) return false;

        balances[msg.sender] -= value;

        sendRobust(to, value);

        Withdrawl(msg.sender, to, value);

        return true;
    }

    function withdrawFrom(address from, address to, uint value) returns (bool ok) {
        if (allowances[from][msg.sender] < value) return false;
        if (balances[from] < value) return false;
        if (value == 0) return false;

        balances[from] -= value;
        allowances[from][msg.sender] -= value;

        sendRobust(to, value);

        Withdrawl(from, to, value);

        return true;
    }

    /*
     *  ERC 20
     */
    function totalSupply() constant returns (uint supply) {
        return this.balance;
    }

    function balanceOf(address who) constant returns (uint value) {
        return balances[who];
    }

    function allowance(address owner, address spender) constant returns (uint _allowance) {
        return allowances[owner][spender];
    }

    function transfer(address to, uint value) returns (bool ok) {
        if (balances[msg.sender] < value) return false;
        if (value == 0) return false;

        balances[msg.sender] -= value;
        balances[to] += value;

        Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint value) returns (bool ok) {
        if (allowances[from][msg.sender] < value) return false;
        if (balances[from] < value) return false;
        if (value == 0) return false;

        balances[from] -= value;
        allowances[from][msg.sender] -= value;
        balances[to] += value;

        Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint value) returns (bool ok) {
        allowances[msg.sender][spender] = value;
        return true;
    }
}
