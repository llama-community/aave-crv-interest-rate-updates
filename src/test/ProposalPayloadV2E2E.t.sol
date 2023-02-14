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
import {ProtocolV2TestBase, InterestStrategyValues, ReserveConfig} from "aave-helpers/ProtocolV2TestBase.sol";
import {IDefaultInterestRateStrategy} from "aave-address-book/AaveV2.sol";

contract ProposalPayloadV2E2ETest is ProtocolV2TestBase, TestWithExecutor {
    uint256 internal constant RAY = 1e27;
    uint256 public mainnetFork;
    uint256 public polygonFork;
    uint256 public proposalId;
    ProposalPayloadPolygon public proposalPayloadPolygon;
    ProposalPayload public proposalPayload;

    // Old Strategies
    IDefaultInterestRateStrategy public constant OLD_INTEREST_RATE_STRATEGY_POLYGON =
        IDefaultInterestRateStrategy(AaveV2PolygonAssets.CRV_INTEREST_RATE_STRATEGY);
    IDefaultInterestRateStrategy public constant OLD_INTEREST_RATE_STRATEGY_ETHEREUM =
        IDefaultInterestRateStrategy(AaveV2EthereumAssets.CRV_INTEREST_RATE_STRATEGY);

    // New Strategies
    address public NEW_INTEREST_RATE_STRATEGY_ETHEREUM;
    address public NEW_INTEREST_RATE_STRATEGY_POLYGON;

    // Underlying
    address public constant CRV = AaveV2EthereumAssets.CRV_UNDERLYING;
    address public constant CRV_POLYGON = AaveV2PolygonAssets.CRV_UNDERLYING;

    // New Strategies
    IDefaultInterestRateStrategy public strategy;
    IDefaultInterestRateStrategy public strategyPolygon;

    function setUp() public {
        mainnetFork = vm.createFork(vm.rpcUrl("mainnet"), 16623608);
        polygonFork = vm.createFork(vm.rpcUrl("polygon"), 39264578);

        // Deploy Payloads
        vm.selectFork(polygonFork);
        proposalPayloadPolygon = new ProposalPayloadPolygon();
        NEW_INTEREST_RATE_STRATEGY_POLYGON = proposalPayloadPolygon.INTEREST_RATE_STRATEGY();
        strategyPolygon = IDefaultInterestRateStrategy(NEW_INTEREST_RATE_STRATEGY_POLYGON);

        vm.selectFork(mainnetFork);
        proposalPayload = new ProposalPayload();
        NEW_INTEREST_RATE_STRATEGY_ETHEREUM = proposalPayload.INTEREST_RATE_STRATEGY();
        strategy = IDefaultInterestRateStrategy(NEW_INTEREST_RATE_STRATEGY_ETHEREUM);
    }

    function testExecuteValidateEthereum() public {
        vm.selectFork(mainnetFork);
        createConfigurationSnapshot("pre-AaveV2Ethereum-interestRateUpdate", AaveV2Ethereum.POOL);

        _selectPayloadExecutor(AaveGovernanceV2.SHORT_EXECUTOR);
        _executePayload(address(proposalPayload));

        // Post-execution assertations
        ReserveConfig[] memory allConfigsEthereum = _getReservesConfigs(AaveV2Ethereum.POOL);

        ReserveConfig memory expectedConfig = ReserveConfig({
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

        _validateReserveConfig(expectedConfig, allConfigsEthereum);

        _validateInterestRateStrategy(
            _findReserveConfigBySymbol(allConfigsEthereum, "CRV").interestRateStrategy,
            ProposalPayload(proposalPayload).INTEREST_RATE_STRATEGY(),
            InterestStrategyValues({
                addressesProvider: address(AaveV2Ethereum.POOL_ADDRESSES_PROVIDER),
                optimalUsageRatio: 70 * (RAY / 100),
                baseVariableBorrowRate: 3 * (RAY / 100),
                stableRateSlope1: 17 * (RAY / 100),
                stableRateSlope2: 300 * (RAY / 100),
                variableRateSlope1: 14 * (RAY / 100),
                variableRateSlope2: 300 * (RAY / 100)
            })
        );

        createConfigurationSnapshot("post-AaveV2Ethereum-interestRateUpdate", AaveV2Ethereum.POOL);
    }

    function testExecuteValidatePolygonV2() public {
        vm.selectFork(polygonFork);
        createConfigurationSnapshot("pre-AaveV2Polygon-interestRateUpdate", AaveV2Polygon.POOL);

        _selectPayloadExecutor(AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR);
        _executePayload(address(proposalPayloadPolygon));

        ReserveConfig[] memory allConfigsPolygon = _getReservesConfigs(AaveV2Polygon.POOL);

        ReserveConfig memory expectedConfigPolygon = ReserveConfig({
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

        _validateReserveConfig(expectedConfigPolygon, allConfigsPolygon);

        _validateInterestRateStrategy(
            _findReserveConfigBySymbol(allConfigsPolygon, "CRV").interestRateStrategy,
            ProposalPayloadPolygon(proposalPayloadPolygon).INTEREST_RATE_STRATEGY(),
            InterestStrategyValues({
                addressesProvider: address(AaveV2Polygon.POOL_ADDRESSES_PROVIDER),
                optimalUsageRatio: 70 * (RAY / 100),
                baseVariableBorrowRate: 3 * (RAY / 100),
                stableRateSlope1: 17 * (RAY / 100),
                stableRateSlope2: 300 * (RAY / 100),
                variableRateSlope1: 14 * (RAY / 100),
                variableRateSlope2: 300 * (RAY / 100)
            })
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

        // At nothing borrowed, liquidity rate should be 0, variable rate should be 3% and stable rate should be 3% as well.
        assertEq(liqRate, 0);
        assertEq(stableRate, 3 * (RAY / 100));
        assertEq(varRate, 3 * (RAY / 100));
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
        assertEq(stableRate, 3200000000000000000000000000);
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
        assertEq(stableRate, 20 * (RAY / 100));
        assertEq(varRate, 17 * (RAY / 100));
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
        assertEq(stableRate, 0 * (RAY / 100));
        assertEq(varRate, 3 * (RAY / 100));
    }

    function testUtilizationAtOneHundredPercentPolygonV2() public {
        vm.selectFork(polygonFork);
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygon.calculateInterestRates(
            CRV_POLYGON,
            0,
            0,
            100 * 1e18,
            68200000000000000000000000,
            2000
        );

        // At max borrow rate, stable rate should be 317% and variable rate should be 317%.
        assertEq(liqRate, 2536000000000000000000000000);
        assertEq(stableRate, 317 * (RAY / 100));
        assertEq(varRate, 317 * (RAY / 100));
    }

    function testUtilizationAtUOptimalPolygonV2() public {
        vm.selectFork(polygonFork);
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygon.calculateInterestRates(
            CRV_POLYGON,
            30 * 1e18,
            0,
            70 * 1e18,
            68200000000000000000000000,
            2000
        );

        // At UOptimal, stable rate should be 17% and variable rate should be 17%.
        assertEq(liqRate, 95200000000000000000000000);
        assertEq(stableRate, 17 * (RAY / 100));
        assertEq(varRate, 17 * (RAY / 100));
    }
}
