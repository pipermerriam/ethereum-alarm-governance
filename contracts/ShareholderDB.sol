import {GroveLib} from "libraries/GroveLib.sol";
import {ERC20} from "contracts/ERC20.sol";
import {owned} from "contracts/owned.sol";
import {DividendDBInterface} from "contracts/DividendDB.sol";


contract ShareholderDBInterface is owned {
    event ShareholderAdded(address who);
    event ShareholderRemoved(address who);
    event SharesAllocated(address to, uint amount);

    function isShareholder(address _address) constant returns (bool);

    function addShareholder(address who) public onlyowner;
    function removeShareholder(address who) public onlyowner;
    function allocateShares(address to, uint amount) public onlyowner;
}


contract ShareholderDB is ShareholderDBInterface, ERC20 {
    using GroveLib for GroveLib.Index;

    // DB of shareholder balances.
    // Note: using Grove so that shareholders and balances are easily
    // enumerable.
    GroveLib.Index shareholders;

    DividendDBInterface dividendsDB;

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
    function totalSupply() constant returns (uint supply) {
        return supply;
    }

    function balanceOf(address _address) constant returns (uint) {
        // TODO: make sure this isn't returning negative values which would get
        // cast to extremely high unsigned values.
        return uint(shareholders.getNodeValue(bytes32(_address)));
    }

    function allowance(address owner, address spender) constant returns (uint _allowance) {
        throw;
    }

    event Transfer(address indexed from, address indexed to, uint value);

    function setBalance(address who, uint balance) internal {
        dividendsDB.recordBalance(who);
        shareholders.insert(bytes32(who), int(balance));
    }

    function transfer(address to, uint value) returns (bool ok) {
        // cannot transfer shares to a non-shareholder
        if (!isShareholder(to) || !isShareholder(msg.sender)) return;

        uint fromBalance = balanceOf(msg.sender);

        // insufficient balance
        if (value == 0 || value > fromBalance) throw;

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
    }

    event Approval(address indexed owner, address indexed spender, uint value);

    function transferFrom(address from, address to, uint value) returns (bool ok) {
        throw;
    }

    function approve(address spender, uint value) returns (bool ok) {
        throw;
    }

    /*
     *  Membership management.
     */
    function isShareholder(address _address) constant returns (bool) {
        return shareholders.exists(bytes32(_address));
    }

    function addShareholder(address who) public onlyowner {
        // already a shareholder
        if (isShareholder(who)) throw;

        // add the shareholder
        setBalance(who, 0);

        // log the addition
        ShareholderAdded(who);
    }

    function removeShareholder(address who) public onlyowner {
        // not a shareholder
        if (!isShareholder(who)) return;

        // move any remaining shares to the unallocatedShares pool
        var amount = balanceOf(who);

        if (amount > 0) {
            unallocatedShares += balanceOf(who);
            Transfer(who, 0x0, amount);
        }

        // record history
        dividendsDB.recordBalance(who);

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
