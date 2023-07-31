// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";

contract TimeAuction is ERC721, ReentrancyGuard {
    error NotEnoughEthSent();
    error AuctionNotLive();
    error NotTheOwner();
    error NoFundsToWithdraw();
    error EthNotSent();
    error AuctionIsLive();
    error UpkeepNotNeeded();
    error AuctionStateIsClose();
    error YouAreWinnerOfTheAuction();

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not the owner.");
        _;
    }

    enum AuctionState {
        OPEN,
        CLOSE
    }

    /* State variables */

    mapping(address => uint256) bidderToValue;

    uint256 private s_winnerValue;
    uint256 private s_lastTimeStamp;
    uint256 private s_auctionDuration;
    uint256 private s_auctionTotalDuration;
    uint256 private s_tokenId;
    address private s_addressOfWinner;
    AuctionState private s_auctionState;

    address payable private immutable i_owner;

    constructor(uint256 auctionDuration, uint256 lastTimestamp, uint256 auctionTotalDuration)
        ERC721("TimeAuction", "TA")
    {
        s_lastTimeStamp = lastTimestamp;
        s_auctionState = AuctionState.OPEN;
        i_owner = payable(msg.sender);
        s_auctionDuration = auctionDuration;
        s_auctionTotalDuration = auctionTotalDuration;
    }

    function bid() public payable {
        if (s_lastTimeStamp + s_auctionDuration < block.timestamp || s_lastTimeStamp > block.timestamp) {
            revert AuctionNotLive();
        }
        if (msg.value <= s_winnerValue) {
            revert NotEnoughEthSent();
        }

        s_winnerValue = msg.value;
        s_addressOfWinner = msg.sender;
        bidderToValue[msg.sender] = msg.value;
    }

    /* This auction could be called by everyone as the auction is finished. If the function has not been called, there is a chainlink automation solution, and the auction will be call automatically at set time. */
    function sendToWinner() public {
        if (s_lastTimeStamp + s_auctionDuration > block.timestamp) {
            revert AuctionIsLive();
        }
        if (s_auctionState == AuctionState.CLOSE) {
            revert AuctionStateIsClose();
        }

        s_auctionState = AuctionState.CLOSE;

        _safeMint(s_addressOfWinner, s_tokenId);
        s_tokenId++;

        s_winnerValue = 0;
        s_addressOfWinner = 0x0000000000000000000000000000000000000000;
        s_lastTimeStamp = s_lastTimeStamp + s_auctionTotalDuration;

        s_auctionState = AuctionState.OPEN;
    }

    function claimFunds() public {
        if (msg.sender == s_addressOfWinner) {
            revert YouAreWinnerOfTheAuction();
        }
        if (bidderToValue[msg.sender] <= 0) {
            revert NoFundsToWithdraw();
        }
        (bool success,) = msg.sender.call{value: bidderToValue[msg.sender]}("");
        if (!success) {
            revert EthNotSent();
        }
        bidderToValue[msg.sender] = 0;
    }

    /* Withdraw funds from contract */
    function withdrawFunds() public onlyOwner nonReentrant {
        if (address(this).balance == 0) {
            revert NoFundsToWithdraw();
        }
        (bool succes,) = i_owner.call{value: address(this).balance}("");
        if (!succes) {
            revert EthNotSent();
        }
    }

    /* Set functions */
    /* Use Unix timestamp format */
    function setLastTimestamp(uint256 time) external onlyOwner {
        s_lastTimeStamp = time;
    }

    /* Time in seconds (1 hour = 3600) */
    function setAuctionDurationTime(uint256 time) external onlyOwner {
        s_auctionDuration = time;
    }

    /* Get functions */

    function getWinnerValue() external view returns (uint256) {
        return s_winnerValue;
    }

    function getAuctionWinner() external view returns (uint256) {
        return s_winnerValue;
    }

    function getWinnerAddress() external view returns (address) {
        return s_addressOfWinner;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getOwnerOfToken(uint256 tokenId) external view returns (address) {
        return ownerOf(tokenId);
    }

    function getBidderToValue(address bidder) external view returns (uint256) {
        return bidderToValue[bidder];
    }

    function getOwnerAddress() external view returns (address) {
        return i_owner;
    }
}
