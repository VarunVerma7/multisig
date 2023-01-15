// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct Proposal {
    address addressToCall;
    bytes dataToExecute;
    address[] proposalSigners; // desired functionality is that you cant unsign a proposal if you voted for it
}

contract Multisig {
    address[] public signers;
    uint256 public threshold;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public signersMapping;

    constructor(address[] memory _signers, uint256 _threshold) {
        require(_threshold > 0 && _threshold <= _signers.length, "Valid Threshold");
        require(_signers.length < 15, "Dont want to DOS brah");

        threshold = _threshold;
        for (uint256 i = 0; i < _signers.length; i++) {
            signers.push(_signers[i]);
            signersMapping[_signers[i]] = true;
        }
    }

    function proposeAction(address addressToCall, bytes memory dataToExecute, uint256 proposalId)
        external
        partOfSigners
    {
        // all existing proposals have to have an array length > 0 since msg.sender is always pushed... therefore if the array length is 0 then we're not overwriting an existing proposal.. right?
        require(proposals[proposalId].proposalSigners.length == 0, "Proposal already exists at this ID");

        proposals[proposalId].proposalSigners.push(msg.sender);

        Proposal storage newProposal = proposals[proposalId];
        newProposal.addressToCall = addressToCall;
        newProposal.dataToExecute = dataToExecute;
   }

    function voteForAction(uint256 proposalIndex) external partOfSigners {
        require(proposals[proposalIndex].proposalSigners.length != 0, "Proposal does not exist at this ID");
        Proposal storage proposal = proposals[proposalIndex];

        for (uint256 i = 0; i < proposal.proposalSigners.length; i++) {
            if (proposal.proposalSigners[i] == msg.sender) {
                revert("Already voted brah"); // can't vote for a proposal twice
            }
        }
        proposal.proposalSigners.push(msg.sender);
    }

    function performAction(uint256 proposalIndex) external partOfSigners {
        Proposal storage proposal = proposals[proposalIndex];
        require(proposal.proposalSigners.length >= threshold, "Not enough signatures");

        (bool success,) = proposal.addressToCall.call(proposal.dataToExecute);
        delete proposals[proposalIndex]; // aware proposal can't be deleted if !success.. but does this result in any issues down the line?

        require(success, "Proposal Failed");
    }

    modifier partOfSigners() {
        require(signersMapping[msg.sender] == true, "Not part of contract signers");
        _;
    }

    fallback() external payable {
        
    }
}
