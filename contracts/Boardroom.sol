import "libraries/GroveLib.sol";

import {Govenor} from "contracts/Govenor.sol";
import {ShareholderDB} from "contracts/ShareholderDB.sol";


//contract Boardroom {
//    Govenor public govenor;
//    ShareholderDB public shareholderDB;
//
//    uint public voting_period_duration;
//    uint public reveal_period_duration;
//    uint public execution_period_duration;
//
//    uint constant MINIMUM_PERIOD = 7 days;
//    uint constant MAXIMUM_PERIOD = 28 days;
//
//    function Boardroom() {
//        govenor = new Govenor();
//        shareholders = new Shareholders();
//
//        // Add the contract creator as a shareholder
//        address(govenor).call(bytes4(sha3("__forward(address,bytes)")), address(shareholders), bytes4(sha3("add_shareholder(address)")), msg.sender);
//        // Allocate all of the initial shares to the contract creator
//        address(govenor).call(bytes4(sha3("__forward(address,bytes)")), address(shareholders), bytes4(sha3("allocate_shares(address,uint)")), msg.sender, shareholders.unallocatedShares());
//
//        voting_period_duration = 7 days;
//        reveal_period_duration = 7 days;
//        execution_period_duration = 7 days;
//    }
//
//    modifier onlygovenor { if (msg.sender != address(govenor)) throw; _ }
//
//    /*
//     *  Motion Configuration
//     */
//    function set_voting_period_duration(uint value) public onlygovenor {
//            // invalid value
//            if (value < MINIMUM_PERIOD || value > MAXIMUM_PERIOD) throw;
//            voting_period_duration = value;
//    }
//
//    function set_reveal_period_duration(uint value) public onlygovenor {
//            // invalid value
//            if (value < MINIMUM_PERIOD || value > MAXIMUM_PERIOD) throw;
//            reveal_period_duration = value;
//    }
//
//    function set_execution_period_duration(uint value) public onlygovenor {
//            // invalid value
//            if (value < MINIMUM_PERIOD || value > MAXIMUM_PERIOD) throw;
//            execution_period_duration = value;
//    }
//
//    uint public _next_id;
//
//    mapping (uint => Motion) motions;
//    mapping (address => uint) motion_to_id;
//
//    enum VoteChoices {
//        Yes,
//        No,
//        Abstain
//    }
//
//    struct Motion {
//        uint id;
//
//        address creator;
//        uint created_at;
//
//        address contract_address;
//
//        // state
//        bool was_executed;
//        bool is_finalized;
//
//        // vote tracking
//        mapping (address => bool) did_vote;
//        mapping (address => bytes32) commit_hashes;
//        
//        // The percentage required for the vote to pass
//        uint pass_percentage;
//        bool did_pass;
//
//        // Tally of the votes
//        uint yes_votes;
//        uint no_votes;
//        uint abstain_votes;
//    }
//
//    modifier onlyshareholder { if (!shareholders.is_shareholder(msg.sender)) throw; _ }
//
//    event MotionCreated(uint id);
//
//    function create_motion(address _address) public onlyshareholder {
//            var motion = motions[_next_id];
//            motion.id = _next_id;
//            _next_id += 1;
//
//            motion.creator = msg.sender;
//            motion.created_at = now;
//            motion.contract_address = _address;
//
//            MotionCreated(motion.id);
//    }
//
//    event VoteCast(uint motion_id, address voter, bytes32 commit_hash);
//
//    function cast_vote(uint motion_id, bytes32 commit_hash) public onlyshareholder {
//            // Invalid motion
//            if (motion_id >= _next_id) throw;
//
//            var motion = motions[motion_id];
//
//            // Already voted
//            if (motion.did_vote[msg.sender]) throw;
//
//            // Voting period has ended
//            if (now > motion.created_at + voting_period_duration) throw;
//
//            // Record and Log the vote
//            motion.did_vote[msg.sender] = true;
//            motion.commit_hashes[msg.sender] = commit_hash;
//            VoteCast(motion_id, msg.sender, commit_hash);
//
//            // lock shares
//            address(govenor).call(bytes4(sha3("__forward(address,bytes)")), address(shareholders), bytes4(sha3("lock_shares(address,uint)")), motion.created_at + voting_period_duration);
//    }
//
//    event VoteRevealed(uint motion_id, address voter, VoteChoices vote);
//
//    function reveal_vote(uint motion_id, VoteChoices vote, bytes32 secret) public onlyshareholder {
//            // Invalid motion
//            if (motion_id >= _next_id) throw;
//
//            var motion = motions[motion_id];
//
//            // Didn't vote
//            if (!motion.did_vote[msg.sender]) throw;
//
//            // Invalid choice
//            if (vote != VoteChoices.Yes && vote != VoteChoices.No && vote != VoteChoices.Abstain) throw;
//
//            // Reveal period has not started
//            if (now < motion.created_at + voting_period_duration) throw;
//
//            // Reveal period has ended
//            if (now > motion.created_at + voting_period_duration + reveal_period_duration) throw;
//
//            bytes32 expected_hash = sha3(secret, vote);
//
//            // Invalid revealed vote
//            if (expected_hash != motion.commit_hashes[msg.sender]) throw;
//
//            // Register the vote.
//            if (vote == VoteChoices.Yes) motion.yes_votes += shareholders.get_num_shares(msg.sender);
//            if (vote == VoteChoices.No) motion.no_votes += shareholders.get_num_shares(msg.sender);
//            if (vote == VoteChoices.Abstain) motion.abstain_votes += shareholders.get_num_shares(msg.sender);
//
//            // Log the vote
//            VoteRevealed(motion_id, msg.sender, vote);
//    }
//
//    function did_motion_pass(uint motion_id) constant returns (bool) {
//            // Invalid motion
//            if (motion_id >= _next_id) throw;
//
//            var motion = motions[motion_id];
//
//            // Reveal period has not ended
//            if (now < motion.created_at + voting_period_duration + reveal_period_duration) throw;
//
//            uint total_votes = motion.yes_votes + motion.no_votes + motion.abstain_votes;
//
//            // No Quorum
//            if (total_votes < shareholders.get_required_quorum_size()) {
//                    return false;
//            }
//
//            uint yes_percentage = motion.yes_votes * 100 / total_votes;
//            return yes_percentage >= motion.pass_percentage;
//    }
//
//    function finalize_motion(uint motion_id) public onlyshareholder {
//            // Invalid motion
//            if (motion_id >= _next_id) throw;
//
//            var motion = motions[motion_id];
//
//            // Already finalized
//            if (motion.is_finalized) throw;
//
//            // Reveal period has not ended
//            if (now < motion.created_at + voting_period_duration + reveal_period_duration) throw;
//
//            motion.is_finalized = true;
//            motion.did_pass = did_motion_pass(motion_id);
//    }
//
//    event MotionExecuted(uint motion_id);
//
//    function execute_motion(uint motion_id) public onlyshareholder {
//            // Invalid motion
//            if (motion_id >= _next_id) throw;
//
//            var motion = motions[motion_id];
//
//            // Not finalized
//            if (!motion.is_finalized) throw;
//
//            // Didn't pass
//            if (!motion.did_pass) throw;
//
//            // Execute period has not started
//            if (now < motion.created_at + voting_period_duration + reveal_period_duration) throw;
//
//            // Execute period has ended
//            if (now > motion.created_at + voting_period_duration + reveal_period_duration + execution_period_duration) throw;
//
//            // Mark the motion as having been executed.
//            motion.was_executed = true;
//
//            // Execute the motion
//            motion.contract_address.call(bytes4(sha3("execute()")));
//            MotionExecuted(motion_id);
//    }
//
//    function __execute(bytes call_data) public {
//            // Lookup the motion based on the caller address
//            uint motion_id = motion_to_id[msg.sender];
//            var motion = motions[motion_id];
//            // This function may only be called by motion addresses.
//            if (motion.contract_address != msg.sender) throw;
//
//            address(govenor).call.value(msg.value)(call_data);
//    }
//}
