// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {TimeAuction} from "../src/TimeAuction.sol";

contract DeployTimeAuction is Script {
    function run() external returns (TimeAuction) {
        vm.startBroadcast();
        TimeAuction timeAuction = new TimeAuction(60, 1689098400, 120);
        vm.stopBroadcast();
        return timeAuction;
    }
}
