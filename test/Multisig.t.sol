// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Multisig.sol";
import "../src/SampleContract.sol";

contract MultisigTest is Test {
    Multisig public multisig;
    SampleContract public sampleContract;

    address public signer1 = address(0x1);
    address public signer2 = address(0x2);
    address public signer3 = address(0x3);
    address public signer4 = address(0x4);
    address public signer5 = address(0x5);

    address[] public allSigners;

    function setUp() public {
        allSigners.push(signer1);
        allSigners.push(signer2);
        allSigners.push(signer3);
        allSigners.push(signer4);
        allSigners.push(signer5);

        multisig = new Multisig(allSigners, 3);
        vm.deal(address(multisig), 100 ether);

        sampleContract = new SampleContract();
    }

    function testProposal() external {
        // action to execute
        address addressToExecuteUpon = address(sampleContract);
        bytes memory dataToExecute = abi.encodeWithSignature("setNum(uint256)", 100);
        uint256 proposalId = 1;
        uint256 gas = 1e6;
        uint256 value = 1e18;

        // test that 3 people can vote for a proposal and the 4th can execute it
        vm.prank(signer1);
        multisig.proposeAction(addressToExecuteUpon, dataToExecute, gas, value, proposalId);

        vm.prank(signer2);
        multisig.voteForAction(proposalId);

        vm.prank(signer3);
        multisig.voteForAction(proposalId);

        vm.prank(signer4);
        multisig.performAction(proposalId);

        // confirm the action of the multisig actually performed
        assertEq(sampleContract.num(), 100);
    }

    function testVoteForProposalThatDoesntExist() external {
        // shouldn't be able to vote for proposal that doesn't exist
        vm.prank(signer2);
        vm.expectRevert("Proposal does not exist at this ID");
        multisig.voteForAction(2);
    }

    function testNonValidSigner() external {
        address nonSigner = address(0x123456);

        // action to execute
        address addressToExecuteUpon = address(sampleContract);
        bytes memory dataToExecute = abi.encodeWithSignature("setNum(uint256)", 100);
        uint256 proposalId = 1;
        uint256 gas = 1e6;
        uint256 value = 1e18;
        // test that a non-signer can't vote
        vm.prank(nonSigner);
        vm.expectRevert("Not part of contract signers");
        multisig.proposeAction(addressToExecuteUpon, dataToExecute, gas, value, proposalId);
    }

    function testVotingTwice() external {
        // action to execute
        address addressToExecuteUpon = address(sampleContract);
        bytes memory dataToExecute = abi.encodeWithSignature("setNum(uint256)", 100);
        uint256 proposalId = 1;
        uint256 gas = 1e6;
        uint256 value = 1e18;
        // valid proposal
        vm.prank(signer1);
        multisig.proposeAction(addressToExecuteUpon, dataToExecute, gas, value, proposalId);

        // shouldn't be able to vote again
        vm.prank(signer1);
        vm.expectRevert("Already voted brah");
        multisig.voteForAction(proposalId);
    }

    function testNotEnoughSignatures() external {
        // action to execute
        address addressToExecuteUpon = address(sampleContract);
        bytes memory dataToExecute = abi.encodeWithSignature("setNum(uint256)", 100);
        uint256 proposalId = 1;
        uint256 gas = 1e6;
        uint256 value = 1e18;

        // valid proposal
        vm.prank(signer1);
        multisig.proposeAction(addressToExecuteUpon, dataToExecute, gas, value, proposalId);

        // shouldn't be able to execute as not enough signatures
        vm.prank(signer1);
        vm.expectRevert("Not enough signatures");
        multisig.performAction(proposalId);
    }

    function testArrayRemoval() external {
        // action to execute
        address addressToExecuteUpon = address(sampleContract);
        bytes memory dataToExecute = abi.encodeWithSignature("setNum(uint256)", 100);
        uint256 proposalId = 1;
        uint256 gas = 1e6;
        uint256 value = 1e18;

        // valid proposal
        vm.prank(signer1);
        multisig.proposeAction(addressToExecuteUpon, dataToExecute, gas, value, proposalId);

        // valid vote
        vm.prank(signer2);
        multisig.voteForAction(proposalId);

        //unvote 
        vm.prank(signer1);
        multisig.unvoteForAction(proposalId);

        //vote 
        vm.prank(signer3);
        multisig.voteForAction(proposalId);

        // valid vote
        vm.prank(signer5);
        multisig.voteForAction(proposalId);

        //vote again
        vm.prank(signer4);
        vm.expectRevert("Cant unvote for something you never voted for");
        multisig.unvoteForAction(proposalId);

        // execute
        vm.prank(signer4);
        multisig.performAction(proposalId);
    }
}
