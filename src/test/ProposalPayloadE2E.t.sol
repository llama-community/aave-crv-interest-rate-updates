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
import {DataTypes} from "@aave-v3-core/protocol/libraries/types/DataTypes.sol";

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
    address public NEW_INTEREST_RATE_STRATEGY_ETHEREUM;
    address public NEW_INTEREST_RATE_STRATEGY_POLYGON;
    address public NEW_INTEREST_RATE_STRATEGY_POLYGON_V3;

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
    IReserveInterestRateStrategyV2 public strategy;
    IReserveInterestRateStrategyV2 public strategyPolygon;
    IDefaultInterestRateStrategy public strategyPolygonV3;

    function setUp() public {
        // To fork at a specific block: vm.createSelectFork(vm.rpcUrl("mainnet"), BLOCK_NUMBER);
        mainnetFork = vm.createFork(vm.rpcUrl("mainnet"), 16435723);
        polygonFork = vm.createFork(vm.rpcUrl("polygon"), 38278604);

        // Deploy Payloads
        vm.selectFork(polygonFork);
        proposalPayloadPolygon = new ProposalPayloadPolygon();
        NEW_INTEREST_RATE_STRATEGY_POLYGON = proposalPayloadPolygon.INTEREST_RATE_STRATEGY();
        NEW_INTEREST_RATE_STRATEGY_POLYGON_V3 = proposalPayloadPolygon.INTEREST_RATE_STRATEGY_V3();
        strategyPolygon = IReserveInterestRateStrategyV2(NEW_INTEREST_RATE_STRATEGY_POLYGON);
        strategyPolygonV3 = IDefaultInterestRateStrategy(NEW_INTEREST_RATE_STRATEGY_POLYGON_V3);

        vm.selectFork(mainnetFork);
        proposalPayload = new ProposalPayload();
        NEW_INTEREST_RATE_STRATEGY_ETHEREUM = proposalPayload.INTEREST_RATE_STRATEGY();
        strategy = IReserveInterestRateStrategyV2(NEW_INTEREST_RATE_STRATEGY_ETHEREUM);

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

    function testExecuteValidateEthereum() public {
        _modifyStrategy();
        vm.selectFork(mainnetFork);

        // Post-execution assertations
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
    }

    function testExecuteValidatePolygonV2() public {
        _modifyStrategy();

        // Post-execution assertations
        vm.selectFork(polygonFork);

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
    }

    function testExecuteValidatePolygonV3() public {
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
            borrowCap: proposalPayloadPolygon.NEW_BORROW_CAP_V3(),
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
    }

    // Interest Strategy Ethereum

    function testUtilizationAtZeroPercentEthereum() public {
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

    function testUtilizationAtOneHundredPercentEthereum() public {
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

    function testUtilizationAtUOptimalEthereum() public {
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

    // Interest Strategy Polygon V2

    function testUtilizationAtZeroPercentPolygonV2() public {
        vm.selectFork(polygonFork);
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygon.calculateInterestRates(
            BAL,
            100 * 1e18,
            0,
            0,
            68200000000000000000000000,
            2000
        );

        // At nothing borrowed, liquidity rate should be 0, variable rate should be 3% and stable rate should be 3%.
        assertEq(liqRate, 0);
        assertEq(stableRate, 0 * (AaveV2Helpers.RAY / 100));
        assertEq(varRate, 3 * (AaveV2Helpers.RAY / 100));
    }

    function testUtilizationAtOneHundredPercentPolygon() public {
        vm.selectFork(polygonFork);
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygon.calculateInterestRates(
            BAL,
            0,
            0,
            100 * 1e18,
            68200000000000000000000000,
            2000
        );

        // At max borrow rate, stable rate should be 87% and variable rate should be 85.75%.
        assertEq(liqRate, 1336000000000000000000000000);
        assertEq(stableRate, 3100000000000000000000000000);
        assertEq(varRate, 1670000000000000000000000000);
    }

    function testUtilizationAtUOptimalPolygon() public {
        vm.selectFork(polygonFork);
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygon.calculateInterestRates(
            BAL,
            20 * 1e18,
            0,
            80 * 1e18,
            68200000000000000000000000,
            2000
        );

        // At UOptimal, stable rate should be % and variable rate should be 14%.
        assertEq(liqRate, 108800000000000000000000000);
        assertEq(stableRate, 10 * (AaveV2Helpers.RAY / 100));
        assertEq(varRate, 17 * (AaveV2Helpers.RAY / 100));
    }

    // Interest Strategy Polygon V3
    function testUtilizationAtZeroPercentPolygonV3() public {
        vm.selectFork(polygonFork);
        DataTypes.CalculateInterestRatesParams memory params = DataTypes.CalculateInterestRatesParams({
            unbacked: 0,
            liquidityAdded: 10e18,
            liquidityTaken: 0,
            totalStableDebt: 0,
            totalVariableDebt: 0,
            averageStableBorrowRate: 0,
            reserveFactor: 2000,
            reserve: BAL_POLYGON,
            aToken: 0x8ffDf2DE812095b1D19CB146E4c004587C0A0692
        });
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygonV3.calculateInterestRates(params);

        // At nothing borrowed, liquidity rate should be 0, variable rate should be 3% and stable rate should be 16%.
        assertEq(liqRate, 0);
        assertEq(stableRate, 16 * (AaveV2Helpers.RAY / 100));
        assertEq(varRate, 3 * (AaveV2Helpers.RAY / 100));
    }

    function testUtilizationAtOneHundredPercentPolygonV3() public {
        vm.selectFork(polygonFork);
        DataTypes.CalculateInterestRatesParams memory params = DataTypes.CalculateInterestRatesParams({
            unbacked: 0,
            liquidityAdded: 0,
            liquidityTaken: 132506495642266527391889,
            totalStableDebt: 0,
            totalVariableDebt: 5e18,
            averageStableBorrowRate: 0,
            reserveFactor: 2000,
            reserve: BAL_POLYGON,
            aToken: 0x8ffDf2DE812095b1D19CB146E4c004587C0A0692
        });
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygonV3.calculateInterestRates(params);

        // At max borrowed, variable rate should be 167% and stable rate should be 16%. (No stable borrowing on BAL)
        assertEq(liqRate, 1336000000000000000000000000);
        assertEq(stableRate, 16 * (AaveV2Helpers.RAY / 100));
        assertEq(varRate, 167 * (AaveV2Helpers.RAY / 100));
    }

    function testUtilizationAtUOptimalPolygonV3() public {
        vm.selectFork(polygonFork);
        DataTypes.CalculateInterestRatesParams memory params = DataTypes.CalculateInterestRatesParams({
            unbacked: 0,
            liquidityAdded: 7493504357733472608111,
            liquidityTaken: 112000000000000000000000,
            totalStableDebt: 0,
            totalVariableDebt: 112000000000000000000000,
            averageStableBorrowRate: 0,
            reserveFactor: 2000,
            reserve: BAL_POLYGON,
            aToken: 0x8ffDf2DE812095b1D19CB146E4c004587C0A0692
        });

        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygonV3.calculateInterestRates(params);

        // At UOptimal, stable rate should be 16% and variable rate should be 14%.
        assertEq(liqRate, 108800000000000000000000000);
        assertEq(stableRate, 16 * (AaveV2Helpers.RAY / 100));
        assertEq(varRate, 17 * (AaveV2Helpers.RAY / 100));
    }
}
