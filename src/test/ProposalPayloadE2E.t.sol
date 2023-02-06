// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

// testing libraries
import "forge-std/Test.sol";

// contract dependencies
import {TestWithExecutor} from "aave-helpers/GovHelpers.sol";
import {AaveGovernanceV2} from "aave-address-book/AaveGovernanceV2.sol";
import {AaveV2Ethereum} from "aave-address-book/AaveV2Ethereum.sol";
import {AaveV3Polygon} from "aave-address-book/AaveV3Polygon.sol";
import {ProposalPayload} from "../ProposalPayload.sol";
import {ProposalPayloadPolygon} from "../ProposalPayloadPolygon.sol";
import {DeployProposals} from "../../script/DeployProposals.s.sol";
import {ProtocolV3TestBase, InterestStrategyValues, ReserveConfig, ReserveTokens, IERC20} from "aave-helpers/ProtocolV3TestBase.sol";
import {IDefaultInterestRateStrategy} from "aave-v3/interfaces/IDefaultInterestRateStrategy.sol";
import {AaveV2Helpers, InterestStrategyValues as InterestStrategyValuesV2, IReserveInterestRateStrategy as IReserveInterestRateStrategyV2, ReserveConfig as ReserveConfigV2} from "./utils/AaveV2Helpers.sol";
import {AaveAddressBookV2} from "./utils/AaveAddressBookV2.sol";
import {DataTypes} from "aave-v3/protocol/libraries/types/DataTypes.sol";

contract ProposalPayloadE2ETest is ProtocolV3TestBase, TestWithExecutor {
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

    // Underlying
    address public constant CRV = AaveV2Ethereum.CRV_UNDERLYING;
    address public constant CRV_POLYGON = AaveV3Polygon.CRV_UNDERLYING;

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
    }

    function testExecuteValidateEthereum() public {
        vm.selectFork(mainnetFork);

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
        vm.selectFork(polygonFork);

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
        vm.selectFork(polygonFork);
        createConfigurationSnapshot("pre-AaveV3Polygon-interestRateUpdate", AaveV3Polygon.POOL);

        _selectPayloadExecutor(AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR);
        _executePayload(address(proposalPayloadPolygon));

        ReserveConfig[] memory allConfigsAfterV3Polygon = _getReservesConfigs(AaveV3Polygon.POOL);

        ReserveConfig memory expectedConfigPolygonV3 = ReserveConfig({
            symbol: "CRV",
            underlying: CRV_POLYGON,
            aToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
            variableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
            stableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
            decimals: 18,
            ltv: 7500,
            liquidationThreshold: 8000,
            liquidationBonus: 10500,
            liquidationProtocolFee: 1000,
            reserveFactor: proposalPayloadPolygon.NEW_RESERVE_FACTOR(),
            usageAsCollateralEnabled: true,
            borrowingEnabled: true,
            interestRateStrategy: _findReserveConfigBySymbol(allConfigsAfterV3Polygon, "CRV").interestRateStrategy,
            stableBorrowRateEnabled: false,
            isActive: true,
            isFrozen: false,
            isSiloed: false,
            isBorrowableInIsolation: false,
            isFlashloanable: false,
            supplyCap: proposalPayloadPolygon.NEW_SUPPLY_CAP_V3(),
            borrowCap: proposalPayloadPolygon.NEW_BORROW_CAP_V3(),
            debtCeiling: 0,
            eModeCategory: 0
        });

        _validateReserveConfig(expectedConfigPolygonV3, allConfigsAfterV3Polygon);

        _validateInterestRateStrategy(
            _findReserveConfigBySymbol(allConfigsAfterV3Polygon, "CRV").interestRateStrategy,
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

        createConfigurationSnapshot("post-AaveV3Polygon-interestRateUpdate", AaveV3Polygon.POOL);
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

        // At max borrow rate, stable rate should be 87% and variable rate should be 85.75%.
        assertEq(liqRate, 1336000000000000000000000000);
        assertEq(stableRate, 3130000000000000000000000000);
        assertEq(varRate, 1670000000000000000000000000);
    }

    function testUtilizationAtUOptimalEthereum() public {
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategy.calculateInterestRates(
            CRV,
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
            CRV_POLYGON,
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
            CRV_POLYGON,
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
            CRV_POLYGON,
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
            reserve: CRV_POLYGON,
            aToken: 0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf
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
            liquidityTaken: 452015246342652694728961,
            totalStableDebt: 0,
            totalVariableDebt: 5e18,
            averageStableBorrowRate: 0,
            reserveFactor: 2000,
            reserve: CRV_POLYGON,
            aToken: 0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf
        });
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygonV3.calculateInterestRates(params);

        // At max borrowed, variable rate should be 167% and stable rate should be 16%. (No stable borrowing on CRV)
        assertEq(liqRate, 1336000000000000000000000000);
        assertEq(stableRate, 16 * (AaveV2Helpers.RAY / 100));
        assertEq(varRate, 167 * (AaveV2Helpers.RAY / 100));
    }

    function testUtilizationAtUOptimalPolygonV3() public {
        vm.selectFork(polygonFork);
        DataTypes.CalculateInterestRatesParams memory params = DataTypes.CalculateInterestRatesParams({
            unbacked: 0,
            liquidityAdded: 8753657347305271039,
            liquidityTaken: 361619200000000000000000,
            totalStableDebt: 0,
            totalVariableDebt: 361619200000000000000000,
            averageStableBorrowRate: 0,
            reserveFactor: 2000,
            reserve: CRV_POLYGON,
            aToken: 0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf
        });

        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygonV3.calculateInterestRates(params);

        // At UOptimal, stable rate should be 16% and variable rate should be 14%.
        assertEq(liqRate, 108800000000000000000000000);
        assertEq(stableRate, 16 * (AaveV2Helpers.RAY / 100));
        assertEq(varRate, 17 * (AaveV2Helpers.RAY / 100));
    }
}
