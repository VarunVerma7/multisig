// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/* 

The intention of this contract is simple: Multiple signers can vote on performing arbitrary proposals.
Signers of the contract are assigned in the constructor

*/

// Proposal should be immutable once created.. apart from who signs it
struct Proposal {
    uint256 gas;
    uint256 value;
    address addressToCall;
    bytes dataToExecute;
    address[] proposalSigners;
}

contract Multisig {
    address[] public signers;
    uint256 public threshold;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public signersMapping;
    bool internal locked;

    constructor(address[] memory _signers, uint256 _threshold) {
        require(
            _threshold > 0 && _threshold <= _signers.length,
            "Valid Threshold"
        );
        require(_signers.length < 15, "Dont want to DOS brah");

        threshold = _threshold;
        for (uint256 i = 0; i < _signers.length; i++) {
            require(!signersMapping[_signers[i]], "No DOOPS");

            signers.push(_signers[i]);
            signersMapping[_signers[i]] = true;
        }
    }

    // External functions for valid signers

    function proposeAction(
        address addressToCall,
        bytes memory dataToExecute,
        uint256 gas,
        uint256 value,
        uint256 proposalId
    ) external partOfSigners {
        // all existing proposals have to have an array length > 0 since msg.sender is always pushed... therefore if the array length is 0 then we're not overwriting an existing proposal.. right?
        require(
            proposals[proposalId].proposalSigners.length == 0,
            "Proposal already exists at this ID"
        );

        proposals[proposalId].proposalSigners.push(msg.sender);

        Proposal storage newProposal = proposals[proposalId];
        newProposal.addressToCall = addressToCall;
        newProposal.dataToExecute = dataToExecute;
        newProposal.gas = gas;
        newProposal.value = value;
    }

    function unvoteForAction(uint256 proposalIndex) external partOfSigners {
        require(
            proposals[proposalIndex].proposalSigners.length != 0,
            "Proposal does not exist at this ID"
        );
        Proposal memory proposal = proposals[proposalIndex];

        uint256 indexOfVoter = 100; // if index is still 100, they never voted, therefore abort
        for (uint256 i = 0; i < proposal.proposalSigners.length; i++) {
            if (proposal.proposalSigners[i] == msg.sender) {
                indexOfVoter = i;
            }
        }

        require(
            indexOfVoter != 100,
            "Cant unvote for something you never voted for"
        );
        removeVoter(indexOfVoter, proposalIndex);
    }

    function voteForAction(uint256 proposalIndex) external partOfSigners {
        require(
            proposals[proposalIndex].proposalSigners.length != 0,
            "Proposal does not exist at this ID"
        );
        Proposal storage proposal = proposals[proposalIndex];

        for (uint256 i = 0; i < proposal.proposalSigners.length; i++) {
            if (proposal.proposalSigners[i] == msg.sender) {
                revert("Already voted brah"); // can't vote for a proposal twice
            }
        }
        proposal.proposalSigners.push(msg.sender);
    }

    function performAction(uint256 proposalIndex)
        external
        partOfSigners
        noReentrant
    {
        Proposal storage proposal = proposals[proposalIndex];
        require(
            proposal.proposalSigners.length >= threshold,
            "Not enough signatures"
        );

        (bool success, ) = proposal.addressToCall.call{
            value: proposal.value,
            gas: proposal.gas
        }(proposal.dataToExecute);
        delete proposals[proposalIndex];

        // require(success, "Proposal Failed"); // success or not, we want to delete the proposal;
    }

    // View functions
    function retrieveProposal(uint256 proposalIndex)
        external
        view
        returns (Proposal memory)
    {
        return proposals[proposalIndex];
    }

    // INTERNAL FUNCTIONS & Modifiers
    function removeVoter(uint256 indexOfVoter, uint256 proposalIndex) internal {
        Proposal storage proposal = proposals[proposalIndex];

        address[] storage arr = proposal.proposalSigners;
        for (uint256 i = indexOfVoter; i < arr.length - 1; i++) {
            arr[i] = arr[i + 1];
        }
        arr.pop();
    }

    modifier partOfSigners() {
        require(signersMapping[msg.sender] == true, "Not authorized, GTFO");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    fallback() external payable {}
}
