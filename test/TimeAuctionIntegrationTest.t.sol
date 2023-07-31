// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {TimeAuction} from "../src/TimeAuction.sol";
import {DeployTimeAuction} from "../script/DeployTimeAuction.s.sol";

contract TimeAuctionIntegrationTest is Test {
    DeployTimeAuction deployer;
    TimeAuction timeAuction;

    address BIDDER = makeAddr("bidder");
    address BIDDER2 = makeAddr("bidder2");
    uint256 public constant BID_VALUE = 1 ether;

    receive() external payable {}

    fallback() external payable {}

    function setUp() public {
        deployer = new DeployTimeAuction();
        timeAuction = deployer.run();
        vm.deal(BIDDER, 5 ether);
        vm.deal(BIDDER2, 5 ether);
    }

    modifier bid() {
        vm.warp(1689098410);
        vm.prank(BIDDER);
        timeAuction.bid{value: BID_VALUE}();
        _;
    }

    function testBidderCanBid() public bid {
        assert(timeAuction.getWinnerValue() == BID_VALUE);
        assert(timeAuction.getWinnerAddress() == BIDDER);
    }

    function testBidderCanClaimFundsIfNotWinning() public bid {
        vm.warp(1689098410);
        vm.prank(BIDDER2);
        timeAuction.bid{value: 2 * BID_VALUE}();

        vm.prank(BIDDER);
        timeAuction.claimFunds();
        assert(BIDDER.balance == 5e18);
    }

    function testOwnerCanWithdrawFundFromContract() public bid {
        uint256 timeAuctionBalance = address(timeAuction).balance;
        uint256 ownerBalance = timeAuction.getOwnerAddress().balance;

        vm.startPrank(timeAuction.getOwnerAddress());
        timeAuction.withdrawFunds();
        vm.stopPrank();

        uint256 afterWithdrawTimeAuctionBalance = address(timeAuction).balance;
        uint256 afterWithdrawOwnerBalance = timeAuction.getOwnerAddress().balance;

        assert(afterWithdrawTimeAuctionBalance == 0);
        assertEq(timeAuctionBalance + ownerBalance, afterWithdrawOwnerBalance);
    }
}
