import {FactoryBase} from "contracts/Factory.sol";
import {transferableInterface, transferable} from "contracts/owned.sol";


contract ExecutableInterface is transferableInterface {
    // The URI where the source code for this contract can be found.
    string public sourceURI;
    // The compiler version used to compile this contract.
    string public compilerVersion;
    // The compile flags used during compilation.
    string public compilerFlags;

    function execute() public onlyowner;
}


contract ExecutableBase is transferable, ExecutableInterface {
}


contract MotionInterface is transferableInterface {
    enum Choices {
        Yes,
        No,
        Abstain
    }

    enum Status {
        Unverified,
        Open,
        Tally,
        Passed,
        Failed,
        Executing,
        Executed
    }

    address createdBy;
    uint createdAt;
    uint openAt;
    uint duration;
    uint quorumSize;

    ExecutableInterface executable;

    // state
    Status status;

    // vote tracking
    mapping (address => bool) didVote;

    // The percentage required for the vote to pass
    uint8 passPercentage;

    struct Tally {
        address[] voters;
        uint tallyIdx;
        uint numVotes;
    }

    // Tally of the votes
    Tally yesVotes;
    Tally noVotes;
    Tally abstainVotes;

    ShareholderDBInterface shareholderDB;

    modifier onlyshareholder { if (!shareholderDB.isShareholder(msg.sender)) throw; _ }
    modifier onlystatus(Status _status) { if (!status == _status) throw; _ }

    event VoteCast(address motion, address who, bytes32 commitHash);

    function setShareholderDB(address _address) public onlyowner;

    function castVote(Choices vote) public onlyshareholder onlystatus(Status.Open);
    function closeVoting() public onlyshareholder onlystatus(Status.Open);
    function tallyVotes() public onlyshareholder onlystatus(Status.Tally);
    function beginExecution() public onlyshareholder onlystatus(Status.Passed);
    function continueExecution() public onlyshareholder onlystatus(Status.Executing);
}


contract Motion is transferable, MotionInterface {
    function Motion(address _createdBy, address _executable, uint _duration, uint _quorumSize, uint8 passPercentage) {
        createdAt = now;
        createdBy = _createdBy;
        executable = ExecutableInterface(_executable);
        duration = _duration;
        quorumSize = _quorumSize;
        passPercentage = _passPercentage;
    }

    function setShareholderDB(address _address) public onlyowner {
        shareholderDB = ShareholderDBInterface(_address);
    }

    function castVote(Choices vote) public onlyshareholder onlystatus(Status.Open) {
        // Already voted
        if (didVote[msg.sender]) return;

        // Invalid choice
        if (vote != Choices.Yes && vote != Choices.No && vote != Choices.Abstain) throw;

        // Record and Log the vote
        didVote[msg.sender] = true;

        // Register the vote.
        if (vote == Choices.Yes) yesVotes.voters.push(msg.sender);
        if (vote == Choices.No) noVotes.voters.push(msg.sender);
        if (vote == Choices.Abstain) abstainVotes.voters.push(msg.sender);

        VoteCast(msg.sender, vote);
    }

    function closeVoting() public onlyshareholder onlystatus(Status.Open) {
        status = Status.Tally;
    }

    function tallyVotes() public onlyshareholder onlystatus(Status.Tally) {
        // TODO: check shares state at beginning of tally and end of tally.  If
        // the state has changed, reset and start over.
    }

    function beginExecution() public onlyshareholder onlystatus(Status.Passed) {
    }

    function continueExecution() public onlyshareholder onlystatus(Status.Executing) {
    }
}


contract MotionFactory is transferable, FactoryBase {
    /*
     *  Voting Configuration
     */
    uint public minimumDebateDuration;

    function setMinimumDebateDuration(uint duration) public onlyowner {
        minimumDebateDuration = duration;
    }

    function getMinimumDebateDuration(uint duration) constant returns (uint) {
        return minimumDebateDuration;
    }

    uint public minimumQuorumSize;

    function setMinimumQuorumSize(uint size) public onlyowner {
        minimumQuorumSize = size;
    }

    function getMinimumQuorumSize(uint size) constant returns (uint) {
        return minimumQuorumSize;
    }

    function createMotion(address _address, uint duration, uint quorumSize) public onlyshareholder {
        // Voting period less than minimum duration.
        if (duration < minimumDebateDuration) return;

        // Quorum size less than minimum
        if (quorumSize < minimumQuorumSize) return;

        var motion = new Motion(msg.sender, _address, duration, quorumSize);

        motion.transferOwnership(owner);

        submitMotion(address(motion));
    }
}
