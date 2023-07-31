// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {TimeAuction} from "../src/TimeAuction.sol";
import {DeployTimeAuction} from "../script/DeployTimeAuction.s.sol";

contract TimeAuctionTest is Test {
    TimeAuction public timeAuction;

    address public BIDDER = makeAddr("player");
    uint256 public constant STARTING_BIDDER_BALANCE = 5 ether;
    uint256 public constant BID_VALUE = 1 ether;

    function setUp() external {
        DeployTimeAuction deployTimeAuction = new DeployTimeAuction();
        timeAuction = deployTimeAuction.run();
        vm.deal(BIDDER, STARTING_BIDDER_BALANCE);
    }

    /* Bid function tests */
    function testBidRevertWhenAuctionNotStarted() public {
        vm.warp(1689098399);
        vm.expectRevert(TimeAuction.AuctionNotLive.selector);
        timeAuction.bid{value: BID_VALUE}();
    }

    function testBidRevertIfAuctionHasEnded() public {
        vm.warp(1689098461);
        vm.expectRevert(TimeAuction.AuctionNotLive.selector);
        timeAuction.bid{value: BID_VALUE}();
    }

    function testBidRevertIfValueIsNotHigherThanPrevious() public {
        vm.warp(1689098410);
        timeAuction.bid{value: BID_VALUE}();
        vm.warp(1689098420);
        vm.expectRevert(TimeAuction.NotEnoughEthSent.selector);
        timeAuction.bid{value: BID_VALUE}();
    }

    modifier bid() {
        vm.warp(1689098410);
        vm.prank(BIDDER);
        timeAuction.bid{value: BID_VALUE}();
        _;
    }

    function testActualAuctionWinnerValue() public bid {
        uint256 winnerValue = timeAuction.getWinnerValue();
        assert(winnerValue == 1e18);
    }

    function testActualAuctionWinnerAddress() public bid {
        address winnerAddress = timeAuction.getWinnerAddress();
        assert(winnerAddress == BIDDER);
    }

    function testResetAuctionValuesAfterSendToWinner() public bid {
        vm.warp(1689098465);
        timeAuction.sendToWinner();

        assert(timeAuction.getWinnerValue() == 0);
        assert(timeAuction.getWinnerAddress() == 0x0000000000000000000000000000000000000000);
        assert(timeAuction.getLastTimeStamp() == 1689098520);
    }

    /* SendToWinner functions test */
    function testRevertWhenFunctionIsLive() public {
        vm.warp(1689098459);
        vm.expectRevert(TimeAuction.AuctionIsLive.selector);
        timeAuction.sendToWinner();
    }

    function testTokenMintPart() public {
        vm.warp(1689098420);
        timeAuction.bid{value: 1 ether}();
    }

    /* ClaimFunds function tests */

    function testRevertWhenUserIsTheWinner() public bid {
        vm.prank(BIDDER);
        vm.expectRevert(TimeAuction.YouAreWinnerOfTheAuction.selector);
        timeAuction.claimFunds();
    }

    function testRevertIfUserDontHaveFundsToClaim() public {
        vm.prank(BIDDER);
        vm.expectRevert(TimeAuction.NoFundsToWithdraw.selector);
        timeAuction.claimFunds();
    }

    /* WithdrawFunds function test */
    function testOnlyOwnerCanWithdrawFunds() public {
        vm.expectRevert();
        timeAuction.withdrawFunds();
    }

    function testCantWithdrawIfBalanceIsZero() public {
        vm.expectRevert();
        timeAuction.withdrawFunds();
    }
}
