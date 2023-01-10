// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";
import {ProposalPayloadPolygon} from "../src/ProposalPayloadPolygon.sol";

contract DeployProposalPayloadPolygon is Script {
    function run() external {
        vm.startBroadcast();
        new ProposalPayloadPolygon();
        vm.stopBroadcast();
    }
}
