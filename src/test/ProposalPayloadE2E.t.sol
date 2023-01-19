// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

// testing libraries
import "@forge-std/Test.sol";
import "@forge-std/console.sol";

// contract dependencies
import {GovHelpers} from "@aave-helpers/GovHelpers.sol";
import {BridgeExecutorHelpers} from "@aave-helpers/BridgeExecutorHelpers.sol";
import {AaveV3Polygon} from "@aave-address-book/AaveV3Polygon.sol";
import {ProposalPayload} from "../ProposalPayload.sol";
import {ProposalPayloadPolygon} from "../ProposalPayloadPolygon.sol";
import {DeployProposals} from "../../script/DeployProposals.s.sol";
import {ProtocolV3TestBase, InterestStrategyValues, ReserveConfig, ReserveTokens, IERC20} from "@aave-helpers/ProtocolV3TestBase.sol";
import {IStateReceiver} from "@governance-crosschain-bridges/dependencies/polygon/fxportal/FxChild.sol";
import {IDefaultInterestRateStrategy} from "@aave-v3-core/interfaces/IDefaultInterestRateStrategy.sol";
import {AaveV2Helpers, InterestStrategyValues as InterestStrategyValuesV2, IReserveInterestRateStrategy as IReserveInterestRateStrategyV2, ReserveConfig as ReserveConfigV2} from "./utils/AaveV2Helpers.sol";
import {AaveAddressBookV2} from "./utils/AaveAddressBookV2.sol";

contract ProposalPayloadE2ETest is ProtocolV3TestBase {
    uint256 internal constant RAY = 1e27;
    uint256 public mainnetFork;
    uint256 public polygonFork;
    uint256 public proposalId;
    ProposalPayloadPolygon public proposalPayloadPolygon;
    ProposalPayload public proposalPayload;

    // Old Strategies
    IDefaultInterestRateStrategy public constant OLD_INTEREST_RATE_STRATEGY_V3_POLYGON =
        IDefaultInterestRateStrategy(0x03733F4E008d36f2e37F0080fF1c8DF756622E6F);
    IReserveInterestRateStrategyV2 public constant OLD_INTEREST_RATE_STRATEGY_POLYGON =
        IReserveInterestRateStrategyV2(0x9025C2d672afA29f43cB59b3035CaCfC401F5D62);
    IReserveInterestRateStrategyV2 public constant OLD_INTEREST_RATE_STRATEGY_ETHEREUM =
        IReserveInterestRateStrategyV2(0xfC0Eace19AA7498e0f36eF1607D282a8d6debbDd);

    // New Strategies
    address public constant NEW_INTEREST_RATE_STRATEGY_ETHEREUM = 0x04c28D6fE897859153eA753f986cc249Bf064f71;
    address public constant NEW_INTEREST_RATE_STRATEGY_POLYGON = 0x80cb7e9E015C5331bF34e06de62443d070FD6654;
    address public constant NEW_INTEREST_RATE_STRATEGY_POLYGON_V3 = 0x4b8D3277d49E114C8F2D6E0B2eD310e29226fe16;

    // Util Addresses
    address public constant CROSSCHAIN_FORWARDER_POLYGON = 0x158a6bC04F0828318821baE797f50B0A1299d45b;
    address public constant BRIDGE_ADMIN = 0x0000000000000000000000000000000000001001;
    address public constant FX_CHILD_ADDRESS = 0x8397259c983751DAf40400790063935a11afa28a;
    address public constant POLYGON_BRIDGE_EXECUTOR = 0xdc9A35B16DB4e126cFeDC41322b3a36454B1F772;

    // Underlying
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address public constant BAL_POLYGON = 0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3;

    string internal ETHEREUM = AaveAddressBookV2.AaveV2Ethereum;
    string internal POLYGON = AaveAddressBookV2.AaveV2Polygon;

    // New Strategies
    IDefaultInterestRateStrategy public constant strategyPolygonV3 =
        IDefaultInterestRateStrategy(NEW_INTEREST_RATE_STRATEGY_POLYGON_V3);
    IReserveInterestRateStrategyV2 strategy = IReserveInterestRateStrategyV2(NEW_INTEREST_RATE_STRATEGY_ETHEREUM);
    IReserveInterestRateStrategyV2 strategyPolygon = IReserveInterestRateStrategyV2(NEW_INTEREST_RATE_STRATEGY_POLYGON);

    function setUp() public {
        // To fork at a specific block: vm.createSelectFork(vm.rpcUrl("mainnet"), BLOCK_NUMBER);
        mainnetFork = vm.createFork(vm.rpcUrl("mainnet"), 16435723);
        polygonFork = vm.createFork(vm.rpcUrl("polygon"), 38278604);

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

    // Utility to transform memory to calldata so array range access is available
    function _cutBytes(bytes calldata input) public pure returns (bytes calldata) {
        return input[64:];
    }

    function testExecute() public {
        _modifyStrategy();

        // Post-execution assertations
        vm.selectFork(polygonFork);

        ReserveConfig[] memory allConfigsAfterV3Polygon = _getReservesConfigs(AaveV3Polygon.POOL);

        ReserveConfig memory expectedConfigPolygonV3 = ReserveConfig({
            symbol: "BAL",
            underlying: BAL_POLYGON,
            aToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
            variableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
            stableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
            decimals: 18,
            ltv: 2000,
            liquidationThreshold: 4500,
            liquidationBonus: 11000,
            liquidationProtocolFee: 1000,
            reserveFactor: 2000,
            usageAsCollateralEnabled: true,
            borrowingEnabled: true,
            interestRateStrategy: _findReserveConfigBySymbol(allConfigsAfterV3Polygon, "BAL").interestRateStrategy,
            stableBorrowRateEnabled: false,
            isActive: true,
            isFrozen: false,
            isSiloed: false,
            isBorrowableInIsolation: false,
            isFlashloanable: false,
            supplyCap: 284_600,
            borrowCap: 256_140,
            debtCeiling: 0,
            eModeCategory: 0
        });

        _validateReserveConfig(expectedConfigPolygonV3, allConfigsAfterV3Polygon);

        _validateInterestRateStrategy(
            _findReserveConfigBySymbol(allConfigsAfterV3Polygon, "BAL").interestRateStrategy,
            ProposalPayloadPolygon(proposalPayloadPolygon).INTEREST_RATE_STRATEGY_V3(),
            InterestStrategyValues({
                addressesProvider: address(AaveV3Polygon.POOL_ADDRESSES_PROVIDER),
                optimalUsageRatio: 80 * (AaveV2Helpers.RAY / 100),
                optimalStableToTotalDebtRatio: 20 * (AaveV2Helpers.RAY / 100),
                baseStableBorrowRate: 16 * (AaveV2Helpers.RAY / 100),
                stableRateSlope1: OLD_INTEREST_RATE_STRATEGY_V3_POLYGON.getStableRateSlope1(),
                stableRateSlope2: OLD_INTEREST_RATE_STRATEGY_V3_POLYGON.getStableRateSlope2(),
                baseVariableBorrowRate: 3 * (AaveV2Helpers.RAY / 100),
                variableRateSlope1: 14 * (AaveV2Helpers.RAY / 100),
                variableRateSlope2: 150 * (AaveV2Helpers.RAY / 100)
            })
        );

        ReserveConfigV2[] memory allConfigsPolygon = AaveV2Helpers._getReservesConfigs(false, POLYGON);

        ReserveConfigV2 memory expectedConfigPolygon = ReserveConfigV2({
            symbol: "BAL",
            underlying: BAL_POLYGON,
            aToken: address(0), // Mock, no-validation because of the "dynamic" deployment on proposal execution
            variableDebtToken: address(0), // Mock, no-validation because of the "dynamic" deployment on proposal exec
            stableDebtToken: address(0), // Mock, no-validation because of the "dynamic" deployment on proposal execution
            decimals: 18,
            ltv: 2000,
            liquidationThreshold: 4500,
            liquidationBonus: 11000,
            reserveFactor: 2000,
            usageAsCollateralEnabled: true,
            borrowingEnabled: true,
            interestRateStrategy: NEW_INTEREST_RATE_STRATEGY_POLYGON,
            stableBorrowRateEnabled: false,
            isActive: true,
            isFrozen: true
        });

        AaveV2Helpers._validateReserveConfig(expectedConfigPolygon, allConfigsPolygon);

        AaveV2Helpers._validateInterestRateStrategy(
            BAL_POLYGON,
            ProposalPayloadPolygon(proposalPayloadPolygon).INTEREST_RATE_STRATEGY(),
            InterestStrategyValuesV2({
                excessUtilization: 20 * (AaveV2Helpers.RAY / 100),
                optimalUtilization: 80 * (AaveV2Helpers.RAY / 100),
                baseVariableBorrowRate: 3 * (AaveV2Helpers.RAY / 100),
                stableRateSlope1: OLD_INTEREST_RATE_STRATEGY_POLYGON.stableRateSlope1(),
                stableRateSlope2: OLD_INTEREST_RATE_STRATEGY_POLYGON.stableRateSlope2(),
                variableRateSlope1: 14 * (AaveV2Helpers.RAY / 100),
                variableRateSlope2: 150 * (AaveV2Helpers.RAY / 100)
            }),
            POLYGON
        );

        vm.selectFork(mainnetFork);
        ReserveConfigV2[] memory allConfigsEthereum = AaveV2Helpers._getReservesConfigs(false, ETHEREUM);

        ReserveConfigV2 memory expectedConfig = ReserveConfigV2({
            symbol: "BAL",
            underlying: BAL,
            aToken: address(0), // Mock, no-validation because of the "dynamic" deployment on proposal execution
            variableDebtToken: address(0), // Mock, no-validation because of the "dynamic" deployment on proposal exec
            stableDebtToken: address(0), // Mock, no-validation because of the "dynamic" deployment on proposal execution
            decimals: 18,
            ltv: 6500,
            liquidationThreshold: 7000,
            liquidationBonus: 10800,
            reserveFactor: 2000,
            usageAsCollateralEnabled: true,
            borrowingEnabled: false,
            interestRateStrategy: NEW_INTEREST_RATE_STRATEGY_ETHEREUM,
            stableBorrowRateEnabled: false,
            isActive: true,
            isFrozen: true
        });

        AaveV2Helpers._validateReserveConfig(expectedConfig, allConfigsEthereum);

        AaveV2Helpers._validateInterestRateStrategy(
            BAL,
            ProposalPayload(proposalPayload).INTEREST_RATE_STRATEGY(),
            InterestStrategyValuesV2({
                excessUtilization: 20 * (AaveV2Helpers.RAY / 100),
                optimalUtilization: 80 * (AaveV2Helpers.RAY / 100),
                baseVariableBorrowRate: 3 * (AaveV2Helpers.RAY / 100),
                stableRateSlope1: OLD_INTEREST_RATE_STRATEGY_ETHEREUM.stableRateSlope1(),
                stableRateSlope2: OLD_INTEREST_RATE_STRATEGY_ETHEREUM.stableRateSlope2(),
                variableRateSlope1: 14 * (AaveV2Helpers.RAY / 100),
                variableRateSlope2: 150 * (AaveV2Helpers.RAY / 100)
            }),
            ETHEREUM
        );

        // ReserveConfig memory expectedAssetConfig = ReserveConfig({
        //     symbol: "BAL",
        //     underlying: BAL_POLYGON,
        //     aToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
        //     variableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
        //     stableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
        //     decimals: 18,
        //     ltv: 6500,
        //     liquidationThreshold: 7000,
        //     liquidationBonus: 10800,
        //     liquidationProtocolFee: 1000,
        //     reserveFactor: 2000,
        //     usageAsCollateralEnabled: true,
        //     borrowingEnabled: false,
        //     interestRateStrategy: _findReserveConfigBySymbol(allConfigsAfterV3Polygon, "BAL")
        //         .interestRateStrategy,
        //     stableBorrowRateEnabled: false,
        //     isActive: true,
        //     isFrozen: false,
        //     isSiloed: false,
        //     isBorrowableInIsolation: false,
        //     isFlashloanable: false,
        //     supplyCap: 100_000_000,
        //     borrowCap: 256_140,
        //     debtCeiling: 2_000_000_00,
        //     eModeCategory: 1
        // });

        // InterestStrategyValues memory expectedStrategy = _getExpectedStrategyPolygon();

        // _validateReserveConfig(expectedAssetConfig, allConfigsAfterV3Polygon);
        // _validateInterestRateStrategy(
        //     ProposalPayloadPolygon(proposalPayloadPolygon).INTEREST_RATE_STRATEGY(),
        //     ProposalPayloadPolygon(proposalPayloadPolygon).INTEREST_RATE_STRATEGY(),
        //     expectedStrategy
        // );
    }

    function testUtilizationAtZeroPercent() public {
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategy.calculateInterestRates(
            BAL,
            100 * 1e18,
            0,
            0,
            68200000000000000000000000,
            2000
        );

        // At nothing borrowed, liquidity rate should be 0, variable rate should be 3% and stable rate should be 3%.
        assertEq(liqRate, 0);
        assertEq(stableRate, 3 * (AaveV2Helpers.RAY / 100));
        assertEq(varRate, 3 * (AaveV2Helpers.RAY / 100));
    }

    function testUtilizationAtOneHundredPercent() public {
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategy.calculateInterestRates(
            BAL,
            0,
            0,
            100 * 1e18,
            68200000000000000000000000,
            2000
        );

        // At max borrow rate, stable rate should be 87% and variable rate should be 85.75%.
        assertEq(liqRate, 1336000000000000000000000000);
        assertEq(stableRate, 3130000000000000000000000000);
        assertEq(varRate, 1670000000000000000000000000);
    }

    function testUtilizationAtUOptimal() public {
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategy.calculateInterestRates(
            BAL,
            20 * 1e18,
            0,
            80 * 1e18,
            68200000000000000000000000,
            2000
        );

        // At UOptimal, stable rate should be % and variable rate should be 14%.
        assertEq(liqRate, 108800000000000000000000000);
        assertEq(stableRate, 13 * (AaveV2Helpers.RAY / 100));
        assertEq(varRate, 17 * (AaveV2Helpers.RAY / 100));
    }

    function _getExpectedStrategyPolygon() public view returns (InterestStrategyValues memory) {
        return
            InterestStrategyValues({
                addressesProvider: address(OLD_INTEREST_RATE_STRATEGY_V3_POLYGON.ADDRESSES_PROVIDER()),
                optimalStableToTotalDebtRatio: 20 * (RAY / 100),
                optimalUsageRatio: 80 * (RAY / 100),
                baseStableBorrowRate: 0,
                baseVariableBorrowRate: 0,
                stableRateSlope1: OLD_INTEREST_RATE_STRATEGY_V3_POLYGON.getStableRateSlope1(),
                stableRateSlope2: 80 * (RAY / 100),
                variableRateSlope1: 575 * (RAY / 10000),
                variableRateSlope2: 80 * (RAY / 100)
            });
    }

    function _modifyStrategy() internal {
        // Pass vote and execute proposal
        vm.selectFork(mainnetFork);
        vm.recordLogs();
        GovHelpers.passVoteAndExecute(vm, proposalId);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(keccak256("StateSynced(uint256,address,bytes)"), entries[5].topics[0]);
        assertEq(address(uint160(uint256(entries[5].topics[2]))), FX_CHILD_ADDRESS);

        // Mock the receive on L2 with the data emitted on StateSynced
        vm.selectFork(polygonFork);
        vm.startPrank(BRIDGE_ADMIN);
        IStateReceiver(FX_CHILD_ADDRESS).onStateReceive(uint256(entries[5].topics[1]), this._cutBytes(entries[5].data));
        vm.stopPrank();

        // Forward time & execute proposal
        BridgeExecutorHelpers.waitAndExecuteLatest(vm, POLYGON_BRIDGE_EXECUTOR);
    }
}
