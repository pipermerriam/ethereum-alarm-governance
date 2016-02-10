import "libraries/GroveLib.sol";


contract ShareholderDBInterface {
    address public owner;

    modifier onlyowner { if (msg.sender != owner) throw; _ }
}


contract ShareholderDB is ShareholderDBInterface {
    using GroveLib for GroveLib.Index;

    // DB of shareholder balances.
    // Note: using Grove so that shareholders and balances are easily
    // enumerable.
    GroveLib.Index shareholders;

    uint public unclaimedDividends;

    uint public _id;

    // The current total supply.
    uint public supply;

    // The number of shares current not allocated to anyone.
    uint public unallocatedShares;

    function () {
        if (msg.value > 0 ) {
            deposits.push(msg.value);
            unclaimedDividends += msg.value * supply;
        }
    }

    function ShareholderDB(uint _supply) {
        owner = msg.sender;
        supply = _supply;
        unallocatedShares = supply;
    }

    function isShareholder(address _address) constant returns (bool) {
        return shareholders.exists(bytes32(_address));
    }

    function recordHistory(address who) internal {
        // Don't update if there are no deposits to track.
        if (deposits.length == 0) return;

        // Either this is the first record or the latest record is older than
        // the latest deposit.
        if (balanceRecords[who].length == 0 || balanceRecords[who][balanceRecords[who].length - 1] < deposits.length - 1) {
            balanceRecords[who].push(deposits.length - 1);
        }

        balanceHistory[who][deposits.length - 1] = balanceOf(who);
    }

    // The next deposit (index) that should be processed
    mapping (address => uint) public depositIterator;
    // The current balanceRecord (index) that is active.
    mapping (address => uint) public historyIterator;

    uint[] public deposits;

    // Map addresses to deposit id's which have recorded balances
    mapping (address => uint[]) public balanceRecords;
    // mapping of address to deposit_id > balance
    mapping (address => mapping (uint => uint)) public balanceHistory;

    // Map of addresses to earned dividends
    mapping (address => uint) public dividends;

    function hasPendingDividends(address who) constant returns (bool) {
        return (deposits.length > 0 && depositIterator[who] <= deposits.length - 1);
    }

    uint constant GAS_RESERVE = 100000;

    function processDividends(address who) public returns (uint iTimes) {
        return processDividends(who, 0);
    }

    function processDividends(address who, uint nTimes) public returns (uint iTimes) {
        while (hasPendingDividends(who) && (nTimes == 0 || iTimes < nTimes) && msg.gas > GAS_RESERVE) {
            // This uses .call(..) to isolate any possible out-of-gas exeception.
            if (address(this).call.gas(msg.gas - GAS_RESERVE)(bytes4(sha3("_processDividends(address)")), who)) {
                iTimes += 1;
            }
            else {
                break;
            }
        }
        return iTimes;
    }

    function _processDividends(address who) public {
        // No deposits
        if (deposits.length == 0) return;

        // No balance history and zero balance so cannot have dividends.
        if (balanceRecords[who].length == 0 && balanceOf(who) == 0) return;

        // Have already processed all deposits
        if (depositIterator[who] > deposits.length - 1) return;

        // The value of the current deposit
        var depositValue = deposits[depositIterator[who]];

        uint balance;


        if (balanceRecords[who].length == 0) {
            // No records of previous balance transfers so current balance should be used.
            balance = balanceOf(who);
        }
        else {
            while (true) {
                var historyIdx = historyIterator[who];

                if (historyIdx > balanceRecords[who].length - 1) {
                    // no more history records, use current balance.
                    balance = balanceOf(who);
                    break;
                }
                else if (balanceRecords[who][historyIdx] >= depositIterator[who]) {
                    // the current record is valid
                    balance = balanceHistory[who][historyIdx];
                    break;
                }
                else {
                    // move onto the next record
                    historyIterator[who] += 1;
                }
            }
        }

        uint dividendValue = deposits[depositIterator[who]] * balance;

        dividends[who] += dividendValue;
        unclaimedDividends -= dividendValue;

        depositIterator[who] += 1;
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

        // record the history
        recordHistory(msg.sender);
        recordHistory(to);

        // update the balances
        GroveLib.insert(shareholders, bytes32(msg.sender), int(fromBalance));
        GroveLib.insert(shareholders, bytes32(to), int(toBalance));

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
    event ShareholderAdded(address who);

    function addShareholder(address who) public onlyowner {
        // already a shareholder
        if (isShareholder(who)) throw;

        // add the shareholder
        shareholders.insert(bytes32(who), 0);

        // log the addition
        ShareholderAdded(who);
    }

    event ShareholderRemoved(address who);

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
        recordHistory(who);

        // remove the shareholder
        shareholders.remove(bytes32(who));

        // log the removal
        ShareholderRemoved(who);
    }


    event SharesAllocated(address to, uint amount);

    function allocateShares(address to, uint amount) public onlyowner {
        // insufficient unallocated shares
        if (amount > unallocatedShares) throw;

        // not a shareholder
        if (!isShareholder(to)) throw;

        uint balance = uint(shareholders.getNodeValue(bytes32(to)));

        // TODO: overflow protection.
        balance += amount;
        unallocatedShares -= amount;

        // update history
        recordHistory(to);

        // update balance
        shareholders.insert(bytes32(to), int(balance));

        // Log the balance change.
        Transfer(0x0, to, amount);
    }
}
