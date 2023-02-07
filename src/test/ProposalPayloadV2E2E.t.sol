// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

// testing libraries
import "forge-std/Test.sol";

// contract dependencies
import {TestWithExecutor} from "aave-helpers/GovHelpers.sol";
import {AaveGovernanceV2} from "aave-address-book/AaveGovernanceV2.sol";
import {AaveV2Ethereum, AaveV2EthereumAssets} from "aave-address-book/AaveV2Ethereum.sol";
import {AaveV2Polygon, AaveV2PolygonAssets} from "aave-address-book/AaveV2Polygon.sol";
import {ProposalPayload} from "../ProposalPayload.sol";
import {ProposalPayloadPolygon} from "../ProposalPayloadPolygon.sol";
import {ProtocolV2TestBase} from "aave-helpers/ProtocolV2TestBase.sol";
import {AaveV2Helpers, InterestStrategyValues as InterestStrategyValuesV2, IReserveInterestRateStrategy as IReserveInterestRateStrategyV2, ReserveConfig as ReserveConfigV2} from "./utils/AaveV2Helpers.sol";
import {AaveAddressBookV2} from "./utils/AaveAddressBookV2.sol";
import {DataTypes} from "aave-v3/protocol/libraries/types/DataTypes.sol";

contract ProposalPayloadV2E2ETest is ProtocolV2TestBase, TestWithExecutor {
    uint256 internal constant RAY = 1e27;
    uint256 public mainnetFork;
    uint256 public polygonFork;
    uint256 public proposalId;
    ProposalPayloadPolygon public proposalPayloadPolygon;
    ProposalPayload public proposalPayload;

    // Old Strategies
    IReserveInterestRateStrategyV2 public constant OLD_INTEREST_RATE_STRATEGY_POLYGON =
        IReserveInterestRateStrategyV2(0x9025C2d672afA29f43cB59b3035CaCfC401F5D62);
    IReserveInterestRateStrategyV2 public constant OLD_INTEREST_RATE_STRATEGY_ETHEREUM =
        IReserveInterestRateStrategyV2(0xfC0Eace19AA7498e0f36eF1607D282a8d6debbDd);

    // New Strategies
    address public NEW_INTEREST_RATE_STRATEGY_ETHEREUM;
    address public NEW_INTEREST_RATE_STRATEGY_POLYGON;

    // Underlying
    address public constant CRV = AaveV2EthereumAssets.CRV_UNDERLYING;
    address public constant CRV_POLYGON = AaveV2PolygonAssets.CRV_UNDERLYING;

    string internal ETHEREUM = AaveAddressBookV2.AaveV2Ethereum;
    string internal POLYGON = AaveAddressBookV2.AaveV2Polygon;

    // New Strategies
    IReserveInterestRateStrategyV2 public strategy;
    IReserveInterestRateStrategyV2 public strategyPolygon;

    function setUp() public {
        // To fork at a specific block: vm.createSelectFork(vm.rpcUrl("mainnet"), BLOCK_NUMBER);
        mainnetFork = vm.createFork(vm.rpcUrl("mainnet"), 16573325);
        polygonFork = vm.createFork(vm.rpcUrl("polygon"), 38997652);

        // Deploy Payloads
        vm.selectFork(polygonFork);
        proposalPayloadPolygon = new ProposalPayloadPolygon();
        NEW_INTEREST_RATE_STRATEGY_POLYGON = proposalPayloadPolygon.INTEREST_RATE_STRATEGY();
        strategyPolygon = IReserveInterestRateStrategyV2(NEW_INTEREST_RATE_STRATEGY_POLYGON);

        vm.selectFork(mainnetFork);
        proposalPayload = new ProposalPayload();
        NEW_INTEREST_RATE_STRATEGY_ETHEREUM = proposalPayload.INTEREST_RATE_STRATEGY();
        strategy = IReserveInterestRateStrategyV2(NEW_INTEREST_RATE_STRATEGY_ETHEREUM);
    }

    function testExecuteValidateEthereum() public {
        vm.selectFork(mainnetFork);
        createConfigurationSnapshot("pre-AaveV2Ethereum-interestRateUpdate", AaveV2Ethereum.POOL);

        _selectPayloadExecutor(AaveGovernanceV2.SHORT_EXECUTOR);
        _executePayload(address(proposalPayload));

        // Post-execution assertations
        ReserveConfigV2[] memory allConfigsEthereum = AaveV2Helpers._getReservesConfigs(false, ETHEREUM);

        ReserveConfigV2 memory expectedConfig = ReserveConfigV2({
            symbol: "CRV",
            underlying: CRV,
            aToken: address(0), // Mock, no-validation because of the "dynamic" deployment on proposal execution
            variableDebtToken: address(0), // Mock, no-validation because of the "dynamic" deployment on proposal exec
            stableDebtToken: address(0), // Mock, no-validation because of the "dynamic" deployment on proposal execution
            decimals: 18,
            ltv: 5200,
            liquidationThreshold: 5800,
            liquidationBonus: 10800,
            reserveFactor: 2000,
            usageAsCollateralEnabled: true,
            borrowingEnabled: false,
            interestRateStrategy: NEW_INTEREST_RATE_STRATEGY_ETHEREUM,
            stableBorrowRateEnabled: false,
            isActive: true,
            isFrozen: false
        });

        AaveV2Helpers._validateReserveConfig(expectedConfig, allConfigsEthereum);

        AaveV2Helpers._validateInterestRateStrategy(
            CRV,
            ProposalPayload(proposalPayload).INTEREST_RATE_STRATEGY(),
            InterestStrategyValuesV2({
                excessUtilization: 30 * (AaveV2Helpers.RAY / 100),
                optimalUtilization: 70 * (AaveV2Helpers.RAY / 100),
                baseVariableBorrowRate: 3 * (AaveV2Helpers.RAY / 100),
                stableRateSlope1: OLD_INTEREST_RATE_STRATEGY_ETHEREUM.stableRateSlope1(),
                stableRateSlope2: OLD_INTEREST_RATE_STRATEGY_ETHEREUM.stableRateSlope2(),
                variableRateSlope1: 14 * (AaveV2Helpers.RAY / 100),
                variableRateSlope2: 300 * (AaveV2Helpers.RAY / 100)
            }),
            ETHEREUM
        );

        createConfigurationSnapshot("post-AaveV2Ethereum-interestRateUpdate", AaveV2Ethereum.POOL);
    }

    function testExecuteValidatePolygonV2() public {
        vm.selectFork(polygonFork);
        createConfigurationSnapshot("pre-AaveV2Polygon-interestRateUpdate", AaveV2Polygon.POOL);

        _selectPayloadExecutor(AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR);
        _executePayload(address(proposalPayloadPolygon));

        ReserveConfigV2[] memory allConfigsPolygon = AaveV2Helpers._getReservesConfigs(false, POLYGON);

        ReserveConfigV2 memory expectedConfigPolygon = ReserveConfigV2({
            symbol: "CRV",
            underlying: CRV_POLYGON,
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
            CRV_POLYGON,
            ProposalPayloadPolygon(proposalPayloadPolygon).INTEREST_RATE_STRATEGY(),
            InterestStrategyValuesV2({
                excessUtilization: 30 * (AaveV2Helpers.RAY / 100),
                optimalUtilization: 70 * (AaveV2Helpers.RAY / 100),
                baseVariableBorrowRate: 3 * (AaveV2Helpers.RAY / 100),
                stableRateSlope1: OLD_INTEREST_RATE_STRATEGY_POLYGON.stableRateSlope1(),
                stableRateSlope2: OLD_INTEREST_RATE_STRATEGY_POLYGON.stableRateSlope2(),
                variableRateSlope1: 14 * (AaveV2Helpers.RAY / 100),
                variableRateSlope2: 300 * (AaveV2Helpers.RAY / 100)
            }),
            POLYGON
        );

        createConfigurationSnapshot("post-AaveV2Polygon-interestRateUpdate", AaveV2Polygon.POOL);
    }

    // Interest Strategy Ethereum

    function testUtilizationAtZeroPercentEthereum() public {
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategy.calculateInterestRates(
            CRV,
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
            CRV,
            0,
            0,
            100 * 1e18,
            68200000000000000000000000,
            2000
        );

        // At max borrow rate, stable rate should be 313% and variable rate should be 317%.
        assertEq(liqRate, 2536000000000000000000000000);
        assertEq(stableRate, 3130000000000000000000000000);
        assertEq(varRate, 3170000000000000000000000000);
    }

    function testUtilizationAtUOptimalEthereum() public {
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategy.calculateInterestRates(
            CRV,
            30 * 1e18,
            0,
            70 * 1e18,
            68200000000000000000000000,
            2000
        );

        // At UOptimal, stable rate should be 13% and variable rate should be 17%.
        assertEq(liqRate, 95200000000000000000000000);
        assertEq(stableRate, 13 * (AaveV2Helpers.RAY / 100));
        assertEq(varRate, 17 * (AaveV2Helpers.RAY / 100));
    }

    // Interest Strategy Polygon V2

    function testUtilizationAtZeroPercentPolygonV2() public {
        vm.selectFork(polygonFork);
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygon.calculateInterestRates(
            CRV_POLYGON,
            100 * 1e18,
            0,
            0,
            68200000000000000000000000,
            2000
        );

        // At nothing borrowed, liquidity rate should be 0, variable rate should be 3% and stable rate should be 0%.
        assertEq(liqRate, 0);
        assertEq(stableRate, 0 * (AaveV2Helpers.RAY / 100));
        assertEq(varRate, 3 * (AaveV2Helpers.RAY / 100));
    }

    function testUtilizationAtOneHundredPercentPolygon() public {
        vm.selectFork(polygonFork);
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygon.calculateInterestRates(
            CRV_POLYGON,
            0,
            0,
            100 * 1e18,
            68200000000000000000000000,
            2000
        );

        // At max borrow rate, stable rate should be 310% and variable rate should be 317%.
        assertEq(liqRate, 2536000000000000000000000000);
        assertEq(stableRate, 3100000000000000000000000000);
        assertEq(varRate, 3170000000000000000000000000);
    }

    function testUtilizationAtUOptimalPolygon() public {
        vm.selectFork(polygonFork);
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygon.calculateInterestRates(
            CRV_POLYGON,
            30 * 1e18,
            0,
            70 * 1e18,
            68200000000000000000000000,
            2000
        );

        // At UOptimal, stable rate should be 10% and variable rate should be 17%.
        assertEq(liqRate, 95200000000000000000000000);
        assertEq(stableRate, 10 * (AaveV2Helpers.RAY / 100));
        assertEq(varRate, 17 * (AaveV2Helpers.RAY / 100));
    }
}
