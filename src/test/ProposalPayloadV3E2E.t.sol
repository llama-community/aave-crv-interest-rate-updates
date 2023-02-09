// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

// testing libraries
import "forge-std/Test.sol";
import "forge-std/console.sol";

// contract dependencies
import {TestWithExecutor} from "aave-helpers/GovHelpers.sol";
import {AaveGovernanceV2} from "aave-address-book/AaveGovernanceV2.sol";
import {AaveV3Polygon, AaveV3PolygonAssets} from "aave-address-book/AaveV3Polygon.sol";
import {ProposalPayloadPolygon} from "../ProposalPayloadPolygon.sol";
import {ProtocolV3TestBase, InterestStrategyValues, ReserveConfig, ReserveTokens, IERC20} from "aave-helpers/ProtocolV3TestBase.sol";
import {IDefaultInterestRateStrategy} from "aave-v3/interfaces/IDefaultInterestRateStrategy.sol";
import {DataTypes} from "aave-v3/protocol/libraries/types/DataTypes.sol";

contract ProposalPayloadV3E2ETest is ProtocolV3TestBase, TestWithExecutor {
    uint256 internal constant RAY = 1e27;
    uint256 public polygonFork;
    uint256 public proposalId;
    ProposalPayloadPolygon public proposalPayloadPolygon;

    // Old Strategies
    IDefaultInterestRateStrategy public constant OLD_INTEREST_RATE_STRATEGY_V3_POLYGON =
        IDefaultInterestRateStrategy(0x03733F4E008d36f2e37F0080fF1c8DF756622E6F);

    // New Strategies
    address public NEW_INTEREST_RATE_STRATEGY_POLYGON_V3;

    // Underlying
    address public constant CRV_POLYGON = AaveV3PolygonAssets.CRV_UNDERLYING;

    // New Strategies
    IDefaultInterestRateStrategy public strategyPolygonV3;

    function setUp() public {
        polygonFork = vm.createFork(vm.rpcUrl("polygon"), 38998033);

        // Deploy Payloads
        vm.selectFork(polygonFork);
        proposalPayloadPolygon = new ProposalPayloadPolygon();
        NEW_INTEREST_RATE_STRATEGY_POLYGON_V3 = proposalPayloadPolygon.INTEREST_RATE_STRATEGY_V3();
        strategyPolygonV3 = IDefaultInterestRateStrategy(NEW_INTEREST_RATE_STRATEGY_POLYGON_V3);
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
                optimalUsageRatio: 70 * (RAY / 100),
                optimalStableToTotalDebtRatio: 20 * (RAY / 100),
                baseStableBorrowRate: 16 * (RAY / 100),
                stableRateSlope1: OLD_INTEREST_RATE_STRATEGY_V3_POLYGON.getStableRateSlope1(),
                stableRateSlope2: OLD_INTEREST_RATE_STRATEGY_V3_POLYGON.getStableRateSlope2(),
                baseVariableBorrowRate: 3 * (RAY / 100),
                variableRateSlope1: 14 * (RAY / 100),
                variableRateSlope2: 300 * (RAY / 100)
            })
        );

        createConfigurationSnapshot("post-AaveV3Polygon-interestRateUpdate", AaveV3Polygon.POOL);
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
        assertEq(stableRate, 16 * (RAY / 100));
        assertEq(varRate, 3 * (RAY / 100));
    }

    function testUtilizationAtOneHundredPercentPolygonV3() public {
        vm.selectFork(polygonFork);
        DataTypes.CalculateInterestRatesParams memory params = DataTypes.CalculateInterestRatesParams({
            unbacked: 0,
            liquidityAdded: 0,
            liquidityTaken: 518119695691228990473501,
            totalStableDebt: 0,
            totalVariableDebt: 5e18,
            averageStableBorrowRate: 0,
            reserveFactor: 2000,
            reserve: CRV_POLYGON,
            aToken: 0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf
        });
        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygonV3.calculateInterestRates(params);

        // At max borrowed, variable rate should be 317% and stable rate should be 16%. (No stable borrowing on CRV)
        assertEq(liqRate, 2536000000000000000000000000);
        assertEq(stableRate, 16 * (RAY / 100));
        assertEq(varRate, 317 * (RAY / 100));
    }

    function testUtilizationAtUOptimalPolygonV3() public {
        vm.selectFork(polygonFork);
        DataTypes.CalculateInterestRatesParams memory params = DataTypes.CalculateInterestRatesParams({
            unbacked: 0,
            liquidityAdded: 1880304308771009526499,
            liquidityTaken: 364000000000000000000000,
            totalStableDebt: 0,
            totalVariableDebt: 364000000000000000000000,
            averageStableBorrowRate: 0,
            reserveFactor: 2000,
            reserve: CRV_POLYGON,
            aToken: 0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf
        });

        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategyPolygonV3.calculateInterestRates(params);

        // At UOptimal, stable rate should be 16% and variable rate should be 17%.
        assertEq(liqRate, 95200000000000000000000000);
        assertEq(stableRate, 16 * (RAY / 100));
        assertEq(varRate, 17 * (RAY / 100));
    }
}
