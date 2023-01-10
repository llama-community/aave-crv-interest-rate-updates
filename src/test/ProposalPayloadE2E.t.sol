// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {ProposalPayload} from "../ProposalPayload.sol";
import {ProposalPayloadPolygon} from "../ProposalPayloadPolygon.sol";
import {DeployProposals} from "../../script/DeployProposals.s.sol";
import {ProtocolV3TestBase, ReserveConfig, ReserveTokens, IERC20} from "@aave-helpers/ProtocolV3TestBase.sol";
import {IStateReceiver} from "governance-crosschain-bridges/contracts/dependencies/polygon/fxportal/FxChild.sol";

contract ProposalPayloadE2ETest is Test {
    uint256 public mainnetFork;
    uint256 public polygonFork;
    uint256 public proposalId;
    ProposalPayloadPolygon public proposalPayloadPolygon;
    ProposalPayload public proposalPayload;

    address public constant CROSSCHAIN_FORWARDER_POLYGON = 0x158a6bC04F0828318821baE797f50B0A1299d45b;
    address public constant BRIDGE_ADMIN = 0x0000000000000000000000000000000000001001;
    address public constant FX_CHILD_ADDRESS = 0x8397259c983751DAf40400790063935a11afa28a;
    address public constant POLYGON_BRIDGE_EXECUTOR = 0xdc9A35B16DB4e126cFeDC41322b3a36454B1F772;

    address public constant BAL = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant BAL_POLYGON = 0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3;

    function setUp() public {
        // To fork at a specific block: vm.createSelectFork(vm.rpcUrl("mainnet"), BLOCK_NUMBER);
        mainnetFork = vm.createFork(vm.rpcUrl("mainnet"), 16378686);
        polygonFork = vm.createFork(vm.rpcUrl("polygon"), 37915443);

        // Deploy Payloads
        vm.selectFork(polygonFork);
        proposalPayloadPolygon = new ProposalPayloadPolygon();

        vm.selectFork(mainnetFork);
        proposalPayload = new ProposalPayload();

        // Create Proposal
        vm.prank(GovHelpers.AAVE_WHALE);
        proposalId = DeployProposals._deployMainnetProposal(
            address(proposalPayload),
            address(proposalPayloadPolygon),
            0x344d3181f08b3186228b93bac0005a3a961238164b8b06cbb5f0428a9180b8a7 // TODO: Replace with actual IPFS Hash
        );
    }

    function testExecute() public {
        // Pre-execution assertations
        ReserveConfig[] memory allConfigsBefore = _getReservesConfigs(AaveV3Polygon.POOL);

        // Pass vote and execute proposal
        GovHelpers.passVoteAndExecute(vm, proposalId);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(keccak256("StateSynced(uint256,address,bytes)"), entries[2].topics[0]);
        assertEq(address(uint160(uint256(entries[2].topics[2]))), FX_CHILD_ADDRESS);

        // 4. mock the receive on l2 with the data emitted on StateSynced
        vm.selectFork(polygonFork);
        vm.startPrank(BRIDGE_ADMIN);
        IStateReceiver(FX_CHILD_ADDRESS).onStateReceive(uint256(entries[2].topics[1]), this._cutBytes(entries[2].data));
        vm.stopPrank();

        // Post-execution assertations
    }
}
