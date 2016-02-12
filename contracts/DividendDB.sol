import {ERC20} from "contracts/ERC20.sol";
import {transferableInterface, transferable} from "contracts/owned.sol";


contract DividendDBInterface is transferableInterface {
    // Log of every deposit made to the contract
    uint[] public deposits;

    ERC20 token;

    uint public unclaimedDividends;

    struct DividendsTracker {
        // Records of the deposit index when the account balance changes.
        uint[] balanceAt;
        // Records of account balances at a specified block.
        mapping (uint => uint) balances;

        // The index of the deposit that should be processed next.
        uint depositIdx;
        // The index of the record in balanceChanges that was used last.
        uint historyIdx;

        // The current dividend balance.
        uint dividendBalance;
    }

    mapping (address => DividendsTracker) trackers;

    modifier onlytoken { if (msg.sender != address(token)) throw; _ }

    /*
     *  Constant Getters
     */
    function balanceAt(address who, uint idx) constant returns (uint);
    function numBalanceRecords(address who) constant returns (uint);
    function balances(address who, uint idx) constant returns (uint);
    function depositIdx(address who) constant returns (uint);
    function historyIdx(address who) constant returns (uint);
    function dividendBalance(address who) constant returns (uint);
    function numDeposits() constant returns (uint);

    function deposit(uint amount) public onlyowner;

    function recordBalance(address who) public onlytoken;

    function hasUnprocessedDividends(address who) constant returns (bool);

    // Amount of gas to keep in reserve when processing dividends in a loop.
    uint constant GAS_RESERVE = 100000;

    function processDividends(address who, uint nTimes) public returns (uint iTimes);
    function processNextDeposit(address who) public returns (uint dividendValue);
}


contract DividendDBBase is transferable, DividendDBInterface {
    /*
     *  Constant Getters
     */
    function balanceAt(address who, uint idx) constant returns (uint) {
        return trackers[who].balanceAt[idx];
    }

    function numBalanceRecords(address who) constant returns (uint) {
        return trackers[who].balanceAt.length;
    }

    function balances(address who, uint idx) constant returns (uint) {
        return trackers[who].balances[idx];
    }

    function depositIdx(address who) constant returns (uint) {
        return trackers[who].depositIdx;
    }

    function historyIdx(address who) constant returns (uint) {
        return trackers[who].historyIdx;
    }

    function dividendBalance(address who) constant returns (uint) {
        return trackers[who].dividendBalance;
    }

    function numDeposits() constant returns (uint) {
        return deposits.length;
    }

    function deposit(uint amount) public onlyowner {
        if (amount > 0) {
            deposits.push(amount);
            // Dividends are handled in units of the total supply.
            unclaimedDividends += amount * token.totalSupply();
        }
    }

    function recordBalance(address who) public onlytoken {
        // No deposits yet so we don't track anything.
        if (deposits.length == 0) return;

        DividendsTracker storage tracker = trackers[who];

        if (tracker.balanceAt.length == 0) {
            tracker.balanceAt.push(deposits.length - 1);
        }
        else if (tracker.balanceAt[tracker.balanceAt.length - 1] < deposits.length - 1) {
            tracker.balanceAt.push(deposits.length - 1);
        }

        tracker.balances[deposits.length - 1] = token.balanceOf(who);
    }

    function hasUnprocessedDividends(address who) constant returns (bool) {
        if (deposits.length == 0) return false;

        var tracker = trackers[who];

        return (tracker.depositIdx <= deposits.length - 1);
    }

    // Amount of gas to keep in reserve when processing dividends in a loop.
    uint constant GAS_RESERVE = 100000;

    function processDividends(address who) public returns (uint iTimes) {
        return processDividends(who, 0);
    }

    function processDividends(address who, uint nTimes) public returns (uint iTimes) {
        while (true) {
            if (msg.gas < GAS_RESERVE) break;
            if (!hasUnprocessedDividends(who)) break;
            if (nTimes != 0 && iTimes >= nTimes) break;

            processNextDeposit(who);
            iTimes += 1;
        }
        return iTimes;
    }

    function processNextDeposit(address who) public returns (uint dividendValue){
        // No deposits
        if (deposits.length == 0) return;

        DividendsTracker storage tracker = trackers[who];

        var numShares = token.balanceOf(who);

        // No balance history and zero balance so cannot have dividends.
        if (tracker.balanceAt.length == 0 && numShares == 0) return;

        // Have already processed all deposits
        if (tracker.depositIdx > deposits.length - 1) return;

        if (tracker.balanceAt.length == 0) {
            // There have been no balance transfers since the first deposit so
            // the current token balance is the correct amount.
            dividendValue = numShares;
        }
        else {
            // Need to find what the share balance was at the time of the
            // deposit.
            while (true) {
                // 
                if (tracker.historyIdx > tracker.balanceAt.length - 1) {
                    // All of the recorded historical balances occurred before
                    // the deposit currently being processed so the latest
                    // balance should be used.
                    dividendValue = numShares;
                    break;
                }
                else if (tracker.balanceAt[tracker.historyIdx] >= tracker.depositIdx) {
                    // The current index of the dividend being processed happen
                    // prior to the balance change at historyIdx and so we
                    // use it as the balance at the time of the deposit.
                    dividendValue = tracker.balances[tracker.balanceAt[tracker.historyIdx]];
                    break;
                }
                else {
                    // There are more recorded historical balances and the
                    // current one occurred prior to the current historical
                    // entry so advance to the next historical entry
                    tracker.historyIdx += 1;
                }
            }
        }

        // Dividends are handled as units of 
        dividendValue *= deposits[tracker.depositIdx];

        tracker.dividendBalance += dividendValue;
        unclaimedDividends -= dividendValue;

        tracker.depositIdx += 1;

        return dividendValue;
    }
}
