// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";
import {AaveGovernanceV2, IExecutorWithTimelock} from "@aave-address-book/AaveGovernanceV2.sol";

library DeployProposals {
    address internal constant CROSSCHAIN_FORWARDER_POLYGON = address(0x158a6bC04F0828318821baE797f50B0A1299d45b);

    function _deployMainnetProposal(
        address payload,
        address payloadPolygon,
        bytes32 ipfsHash
    ) internal returns (uint256 proposalId) {
        require(payload != address(0), "ERROR: PAYLOAD can't be address(0)");
        require(ipfsHash != bytes32(0), "ERROR: IPFS_HASH can't be bytes32(0)");
        address[] memory targets = new address[](2);
        targets[0] = payload;
        targets[1] = CROSSCHAIN_FORWARDER_POLYGON;
        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;
        string[] memory signatures = new string[](2);
        signatures[0] = "execute()";
        signatures[1] = "execute(address)";
        bytes[] memory calldatas = new bytes[](2);
        calldatas[0] = "";
        calldatas[1] = abi.encode(payloadPolygon);
        bool[] memory withDelegatecalls = new bool[](2);
        withDelegatecalls[0] = true;
        withDelegatecalls[1] = true;

        return
            AaveGovernanceV2.GOV.create(
                IExecutorWithTimelock(AaveGovernanceV2.SHORT_EXECUTOR),
                targets,
                values,
                signatures,
                calldatas,
                withDelegatecalls,
                ipfsHash
            );
    }
}

contract DeployProposal is Script {
    function run() external {
        vm.startBroadcast();
        DeployProposals._deployMainnetProposal(
            address(0), // TODO: replace with mainnet payload address
            address(0), // TODO: replace with polygon payload address
            bytes32(0) // TODO: replace with actual ipfshash
        );
        vm.stopBroadcast();
    }
}
