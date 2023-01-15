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
        sampleContract = new SampleContract();
    }

    function testProposal() external {
        // action to execute
        address addressToExecuteUpon = address(sampleContract);
        bytes memory dataToExecute = abi.encodeWithSignature("setNum(uint256)", 100);
        uint proposalId = 1;

        // test that 3 people can vote for a proposal and the 4th can execute it
        vm.prank(signer1);
        multisig.proposeAction(addressToExecuteUpon, dataToExecute, proposalId);

        vm.prank(signer2);
        multisig.voteForAction(proposalId);

        vm.prank(signer3);
        multisig.voteForAction(proposalId);

        vm.prank(signer4);
        multisig.performOperation(proposalId);
        

        // confirm the action of the multisig actually performed
        assertEq(sampleContract.num(), 100);
    }
}
