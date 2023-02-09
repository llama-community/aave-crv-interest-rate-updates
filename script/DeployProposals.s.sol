// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";
import {AaveGovernanceV2} from "aave-address-book/AaveGovernanceV2.sol";
import {GovHelpers} from "aave-helpers/GovHelpers.sol";

contract DeployProposal is Script {
    function run() external {
        GovHelpers.Payload[] memory payloads = new GovHelpers.Payload[](2);
        payloads[0] = GovHelpers.buildMainnet(
            address(0) // TODO: Add
        );
        payloads[1] = GovHelpers.buildPolygon(
            address(0) // TODO: add
        );
        vm.startBroadcast();
        GovHelpers.createProposal(
            AaveGovernanceV2.SHORT_EXECUTOR,
            payloads,
            0x05097b8a0818a75c1db7d54dfd0299581cac0218a058017acb4726f7cc49657e // TODO: Replace with ipfs hash
        );
        vm.stopBroadcast();
    }
}
