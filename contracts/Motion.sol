import {transferableInterface, transferable} from "contracts/owned.sol";
import {FactoryBase} from "contracts/Factory.sol";
import {ShareholderDBInterface} from "contracts/ShareholderDB.sol";


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
        NeedsConfiguration,
        NeedsValidation,
        Open,
        Tally,
        Passed,
        Failed,
        Executing,
        Executed
    }

    address public createdBy;
    uint public createdAt;
    uint public openAt;
    uint public duration;
    uint public quorumSize;
    // The percentage required for the vote to pass
    uint8 public passPercentage;


    ExecutableInterface public executable;

    // state
    Status public status;

    // vote tracking
    mapping (address => bool) public didVote;

    struct Tally {
        address[] voters;
        uint tallyIdx;
        uint numVotes;
    }

    // Tally of the votes
    Tally public yesVotes;
    Tally public noVotes;
    Tally public abstainVotes;

    ShareholderDBInterface public shareholderDB;

    modifier onlyshareholder { if (!shareholderDB.isShareholder(msg.sender)) throw; _ }
    modifier onlystatus(Status _status) { if (status != _status) throw; _ }
    modifier onlycreator { if (msg.sender != createdBy) throw; _ }

    event VoteCast(address who, Choices vote);

    function setShareholderDB(address _address) public onlyowner;

    function configure(uint _quorumSize, uint _duration, uint8 _passPercentage, address _executable) public onlycreator onlystatus(Status.NeedsConfiguration);
    function accept() public onlyowner onlystatus(Status.NeedsValidation);
    function reject() public onlyowner onlystatus(Status.NeedsValidation);

    function castVote(Choices vote) public onlyshareholder onlystatus(Status.Open);
    function closeVoting() public onlyshareholder onlystatus(Status.Open);
    function tallyVotes() public onlyshareholder onlystatus(Status.Tally);
    function beginExecution() public onlyshareholder onlystatus(Status.Passed);
    function continueExecution() public onlyshareholder onlystatus(Status.Executing);
}


contract Motion is transferable, MotionInterface {
    function Motion(address _createdBy) {
        createdAt = now;
        createdBy = _createdBy;
    }

    function setShareholderDB(address _address) public onlyowner {
        shareholderDB = ShareholderDBInterface(_address);
    }

    function configure(uint _quorumSize, uint _duration, uint8 _passPercentage, address _executable) public onlycreator onlystatus(Status.NeedsConfiguration) {
        executable = ExecutableInterface(_executable);
        quorumSize = _quorumSize;
        duration = _duration;
        passPercentage = _passPercentage;

        status = Status.NeedsValidation;
    }

    function accept() public onlyowner onlystatus(Status.NeedsValidation) {
        // Open it for voting.
        status = Status.Open;
    }

    function reject() public onlyowner onlystatus(Status.NeedsValidation) {
        // Put it back into configuration state.
        status = Status.NeedsConfiguration;
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
    function MotionFactory(string _sourceURI, string _compilerVersion, string _compilerFlags) 
             FactoryBase(_sourceURI, _compilerVersion, _compilerFlags) {
    }

    function buildContract(address creator) internal returns (address) {
        var motion = new Motion(msg.sender);
        motion.transferOwnership(owner);
        return address(motion);
    }
}
