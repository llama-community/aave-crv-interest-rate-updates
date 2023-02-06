// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";
import {ProposalPayload} from "../src/ProposalPayload.sol";

contract DeployProposalPayload is Script {
    function run() external {
        vm.startBroadcast();
        new ProposalPayload();
        vm.stopBroadcast();
    }
}
