import {GroveLib} from "libraries/GroveLib.sol";
import {ERC20} from "contracts/ERC20.sol";
import {transferableInterface, transferable} from "contracts/owned.sol";
import {DividendDBInterface} from "contracts/DividendDB.sol";


contract ShareholderDBInterface is transferableInterface, ERC20 {
    event ShareholderAdded(address who);
    event ShareholderRemoved(address who);
    event SharesAllocated(address to, uint amount);

    function isShareholder(address _address) constant returns (bool);
    function getJoinBlock(address _address) constant returns (uint);
    function getNextShareholder(address _address) constant returns (address);
    function getPreviousShareholder(address _address) constant returns (address);
    function queryShareholders(bytes2 operator, uint blockNumber) constant returns (address);

    function addShareholder(address who) public onlyowner;
    function removeShareholder(address who) public onlyowner;
    function allocateShares(address to, uint amount) public onlyowner;
}


contract ShareholderDB is transferable, ShareholderDBInterface {
    using GroveLib for GroveLib.Index;

    /*
     *  Dividends integration
     */
    DividendDBInterface dividendsDB;

    function setBalance(address who, uint balance) internal {
        if (address(dividendsDB) != 0x0) {
            dividendsDB.recordBalance(who);
        }
        balances[who] = balance;
    }

    uint public _id;

    // The current total supply.
    uint public supply;

    // The number of shares current not allocated to anyone.
    uint public unallocatedShares;

    function ShareholderDB(uint _supply) {
        owner = msg.sender;
        supply = _supply;
        unallocatedShares = supply;
    }

    /*
     *  ERC20
     */
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;

    function totalSupply() constant returns (uint) {
        return supply;
    }

    function balanceOf(address _address) constant returns (uint) {
        return balances[_address];
    }

    function allowance(address owner, address spender) constant returns (uint _allowance) {
        return allowances[owner][spender];
    }

    event Transfer(address indexed from, address indexed to, uint value);

    function transfer(address to, uint value) returns (bool ok) {
        // cannot transfer shares to a non-shareholder
        if (!isShareholder(to) || !isShareholder(msg.sender)) return false;

        uint fromBalance = balanceOf(msg.sender);

        // insufficient balance
        if (value == 0 || value > fromBalance) return false;

        uint toBalance = balanceOf(to);

        // overflow protection
        if (toBalance + value < toBalance) throw;

        // move the shares
        fromBalance -= value;
        toBalance += value;

        setBalance(msg.sender, fromBalance);
        setBalance(to, toBalance);

        // Log the transfer
        Transfer(msg.sender, to, value);

        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint value);

    function transferFrom(address from, address to, uint value) returns (bool ok) {
        // insufficient allowance
        if (allowances[from][msg.sender] < value) return false;

        // not shareholder
        if (!isShareholder(from) || !isShareholder(to)) return false;

        var fromBalance = balanceOf(from);

        // insufficient balance
        if (value == 0 || fromBalance < value) return false;

        var toBalance = balanceOf(to);

        fromBalance -= value;
        toBalance += value;
        allowances[from][msg.sender] -= value;

        setBalance(from, fromBalance);
        setBalance(to, toBalance);

        Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint value) returns (bool ok) {
        allowances[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    /*
     *  Membership management.
     */
    // DB of shareholder join blocks.
    GroveLib.Index shareholders;

    function getJoinBlock(address _address) constant returns (uint) {
        return uint(shareholders.getNodeValue(bytes32(_address)));
    }

    function queryShareholders(bytes2 operator, uint blockNumber) constant returns (address) {
        return address(shareholders.query(operator, int(blockNumber)));
    }

    function getNextShareholder(address _address) constant returns (address) {
        return address(shareholders.getNextNode(bytes32(_address)));
    }

    function getPreviousShareholder(address _address) constant returns (address) {
        return address(shareholders.getPreviousNode(bytes32(_address)));
    }

    function isShareholder(address _address) constant returns (bool) {
        return shareholders.exists(bytes32(_address));
    }

    function addShareholder(address who) public onlyowner {
        // already a shareholder
        if (isShareholder(who)) throw;

        // cannot add empty address as shareholder
        if (who == 0x0) throw;

        // add the shareholder
        shareholders.insert(bytes32(who), int(block.number));

        // log the addition
        ShareholderAdded(who);
    }

    function removeShareholder(address who) public onlyowner {
        // not a shareholder
        if (!isShareholder(who)) throw;

        // move any remaining shares to the unallocatedShares pool
        var amount = balanceOf(who);

        if (amount > 0) {
            unallocatedShares += balanceOf(who);
            Transfer(who, 0x0, amount);
        }

        // record history
        setBalance(who, 0);

        // remove the shareholder
        shareholders.remove(bytes32(who));

        // log the removal
        ShareholderRemoved(who);
    }

    function allocateShares(address who, uint amount) public onlyowner {
        // insufficient unallocated shares
        if (amount > unallocatedShares) throw;

        // not a shareholder
        if (!isShareholder(who)) throw;

        uint balance = balanceOf(who);

        // TODO: overflow protection.
        balance += amount;
        unallocatedShares -= amount;

        // update balance
        setBalance(who, balance);

        // Log the balance change.
        Transfer(0x0, who, amount);
    }
}
