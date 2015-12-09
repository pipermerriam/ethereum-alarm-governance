import "libraries/GroveLib.sol";


contract Govenor {
    address owner;

    function Govenor() {
        owner = msg.sender;
    }

    modifier onlyowner { if (msg.sender != owner) throw; _ }

    function __forward(address to, bytes call_data) onlyowner returns (bool) {
        return to.call.value(msg.value)(call_data);
    }

    function transfer_owner(address new_owner) onlyowner {
        if (msg.sender != owner) throw;
        owner = new_owner;
    }
}


contract Shareholders {
    Govenor govenor;

    GroveLib.Index shareholders;

    // 1,000,000 (1 million)
    uint constant INITIAL_SHARES = 1000000;

    uint public unallocated_shares;

    uint public maximum_lock_duration;
    mapping (address => uint) public locked_until;

    function Shareholders() {
        govenor = new Govenor();
        unallocated_shares = 0;
        maximum_lock_duration = 7 days;
    }

    modifier onlygovenor { if (msg.sender != address(govenor)) throw; _ }

    function is_shareholder(address _address) constant returns (bool) {
        return GroveLib.exists(shareholders, bytes32(_address));
    }

    function get_num_shares(address _address) constant returns (uint) {
        if (!is_shareholder(_address)) throw;
        return uint(GroveLib.getNodeValue(shareholders, bytes32(_address)));
    }

    function set_maximum_lock_duration(uint duration) public onlygovenor {
        if (duration > 28 days) throw;
        maximum_lock_duration = duration;
    }

    function lock_shares(address _address, uint until) public onlygovenor {
        // in the past
        if (now > until) throw;

        // too far in the future
        if (until > now + maximum_lock_duration) throw;

        // lock the shares in a manner that can't shorten the duration if they
        // are currently locked.
        if (until > locked_until[_address]) {
            locked_until[_address] = until;
        }
    }

    function unlock_shares(address _address) public onlygovenor {
        locked_until[_address] = 0;
    }

    event ShareholderAdded(address _address);

    function add_shareholder(address _address) public onlygovenor {
        // already a shareholder
        if (is_shareholder(_address)) throw;

        // add the shareholder
        GroveLib.insert(shareholders, bytes32(_address), 0);

        // log the addition
        ShareholderAdded(_address);
    }

    event ShareholderRemoved(address _address);

    function remove_shareholder(address _address) public onlygovenor {
        // not a shareholder
        if (!is_shareholder(_address)) throw;

        // move any remaining shares to the unallocated_share pool
        unallocated_shares += uint(GroveLib.getNodeValue(shareholders, bytes32(_address)));

        // remove the shareholder
        GroveLib.remove(shareholders, bytes32(_address));

        // log the removal
        ShareholderRemoved(_address);
    }

    event SharesTransferred(address from, address to, uint amount);

    function transfer_shares(address to, uint amount) public {
        // cannot transfer shares to a non-shareholder
        if (!is_shareholder(to)) throw;

        // shares are locked.
        if (locked_until[msg.sender] > now) throw;

        uint source_balance = uint(GroveLib.getNodeValue(shareholders, bytes32(msg.sender)));

        // insufficient balance
        if (source_balance <= 0 || amount > source_balance) throw;

        uint target_balance = uint(GroveLib.getNodeValue(shareholders, bytes32(to)));

        // overflow protection
        if (target_balance + amount < target_balance) throw;

        // move the shares
        target_balance += amount;
        source_balance -= amount;

        GroveLib.insert(shareholders, bytes32(to), int(target_balance));
        GroveLib.insert(shareholders, bytes32(msg.sender), int(source_balance));

        // Log the transfer
        SharesTransferred(msg.sender, to, amount);
    }

    event SharesAllocated(address to, uint amount);

    function allocate_shares(address to, uint amount) public onlygovenor {
        // insufficient unallocated shares
        if (amount > unallocated_shares) throw;

        // not a shareholder
        if (!is_shareholder(to)) throw;

        uint balance = uint(GroveLib.getNodeValue(shareholders, bytes32(to)));

        balance += amount;
        unallocated_shares -= amount;

        GroveLib.insert(shareholders, bytes32(to), int(balance));
        SharesAllocated(to, amount);
    }
}


contract MotionContract {
    function execute() public;
}


contract Boardroom {
    Govenor govenor;
    Shareholders shareholders;

    uint public voting_period_duration;
    uint public reveal_period_duration;
    uint public execution_period_duration;

    uint constant MINIMUM_PERIOD = 7 days;
    uint constant MAXIMUM_PERIOD = 28 days;

    function Boardroom() {
        govenor = new Govenor();
        shareholders = new Shareholders();

        // Add the contract creator as a shareholder
        address(govenor).call(bytes4(sha3("__forward(address,bytes)")), address(shareholders), bytes4(sha3("add_shareholder(address)")), msg.sender);
        // Allocate all of the initial shares to the contract creator
        address(govenor).call(bytes4(sha3("__forward(address,bytes)")), address(shareholders), bytes4(sha3("allocate_shares(address,uint)")), msg.sender, shareholders.unallocated_shares());

        voting_period_duration = 7 days;
        reveal_period_duration = 7 days;
        execution_period_duration = 7 days;
    }

    modifier onlygovenor { if (msg.sender != address(govenor)) throw; _ }

    /*
     *  Motion Configuration
     */
    function set_voting_period_duration(uint value) public onlygovenor {
            // invalid value
            if (value < MINIMUM_PERIOD || value > MAXIMUM_PERIOD) throw;
            voting_period_duration = value;
    }

    function set_reveal_period_duration(uint value) public onlygovenor {
            // invalid value
            if (value < MINIMUM_PERIOD || value > MAXIMUM_PERIOD) throw;
            reveal_period_duration = value;
    }

    function set_execution_period_duration(uint value) public onlygovenor {
            // invalid value
            if (value < MINIMUM_PERIOD || value > MAXIMUM_PERIOD) throw;
            execution_period_duration = value;
    }

    uint public _next_id;

    mapping (uint => Motion) motions;
    mapping (address => uint) motion_to_id;

    enum VoteChoices {
        Yes,
        No,
        Abstain
    }

    struct Motion {
        uint id;

        address creator;
        uint created_at;

        address contract_address;
        bool was_executed;

        mapping (address => bool) did_vote;
        mapping (address => bytes32) commit_hashes;
        uint yes_votes;
        uint no_votes;
        uint abstain_votes;
    }

    modifier onlyshareholder { if (!shareholders.is_shareholder(msg.sender)) throw; _ }

    event MotionCreated(uint id);

    function create_motion(address _address) public onlyshareholder {
            var motion = motions[_next_id];
            motion.id = _next_id;
            _next_id += 1;

            motion.creator = msg.sender;
            motion.created_at = now;
            motion.contract_address = _address;

            MotionCreated(motion.id);
    }

    event VoteCast(uint motion_id, address voter, bytes32 commit_hash);

    function cast_vote(uint motion_id, bytes32 commit_hash) public onlyshareholder {
            // Invalid motion
            if (motion_id >= _next_id) throw;

            var motion = motions[motion_id];

            // Already voted
            if (motion.did_vote[msg.sender]) throw;

            // Voting period has ended
            if (now > motion.created_at + voting_period_duration) throw;

            // Record and Log the vote
            motion.did_vote[msg.sender] = true;
            motion.commit_hashes[msg.sender] = commit_hash;
            VoteCast(motion_id, msg.sender, commit_hash);

            // lock shares
            address(govenor).call(bytes4(sha3("__forward(address,bytes)")), address(shareholders), bytes4(sha3("lock_shares(address,uint)")), motion.created_at + voting_period_duration);
    }

    event VoteRevealed(uint motion_id, address voter, VoteChoices vote);

    function reveal_vote(uint motion_id, VoteChoices vote, bytes32 secret) public onlyshareholder {
            // Invalid motion
            if (motion_id >= _next_id) throw;

            var motion = motions[motion_id];

            // Didn't vote
            if (!motion.did_vote[msg.sender]) throw;

            // Invalid choice
            if (vote != VoteChoices.Yes && vote != VoteChoices.No && vote != VoteChoices.Abstain) throw;

            // Reveal period has not started
            if (now < motion.created_at + voting_period_duration) throw;

            // Reveal period has ended
            if (now > motion.created_at + voting_period_duration + reveal_period_duration) throw;

            bytes32 expected_hash = sha3(secret, vote);

            // Invalid revealed vote
            if (expected_hash != motion.commit_hashes[msg.sender]) throw;

            // Register the vote.
            if (vote == VoteChoices.Yes) motion.yes_votes += shareholders.get_num_shares(msg.sender);
            if (vote == VoteChoices.No) motion.no_votes += shareholders.get_num_shares(msg.sender);
            if (vote == VoteChoices.Abstain) motion.abstain_votes += shareholders.get_num_shares(msg.sender);

            // Log the vote
            VoteRevealed(motion_id, msg.sender, vote);
    }

    function execute_motion(uint motion_id) public onlyshareholder {
            // Invalid motion
            if (motion_id >= _next_id) throw;

            var motion = motions[motion_id];

            // Execute period has not started
            if (now < motion.created_at + voting_period_duration + reveal_period_duration) throw;

            // Execute period has ended
            if (now > motion.created_at + voting_period_duration + reveal_period_duration + execution_period_duration) throw;

            // Mark the motion as having been executed.
            motion.was_executed = true;

            // Execute the motion
            motion.contract_address.call(bytes4(sha3("execute()")));
    }

    function __execute(bytes call_data) public {
            // Lookup the motion based on the caller address
            uint motion_id = motion_to_id[msg.sender];
            var motion = motions[motion_id];
            // This function may only be called by motion addresses.
            if (motion.contract_address != msg.sender) throw;

            address(govenor).call.value(msg.value)(call_data);
    }
}
