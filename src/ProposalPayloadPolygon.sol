// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {AaveV2Polygon, AaveV2PolygonAssets} from "aave-address-book/AaveV2Polygon.sol";
import {AaveV3Polygon, AaveV3PolygonAssets} from "aave-address-book/AaveV3Polygon.sol";

/**
 * @title CRV Interest Rate Curve Upgrade
 * @author Llama
 * @notice Amend CRV interest rate parameters on the Aave Polygon v2 and Aave Polygon v3 liquidity pools, as well as borrow, supply cap and reserve factor for v3.
 * Governance Forum Post: https://governance.aave.com/t/arfc-crv-interest-rate-curve-upgrade/11337
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x56aaf192f5cad8277b0e7c82abad030c62bb8fcfe4f2640ce5b896ab04397c20
 */
contract ProposalPayloadPolygon {
    address public constant INTEREST_RATE_STRATEGY_V3 = 0xBefcd01681224555b74eAC87207eaF9Bc3361F59;
    address public constant INTEREST_RATE_STRATEGY = 0xE4621DfD503A533f42bB5a45162eA3e5233Acd5F;
    uint256 public constant NEW_BORROW_CAP_V3 = 900_190;
    uint256 public constant NEW_SUPPLY_CAP_V3 = 1_125_240;
    uint256 public constant NEW_RESERVE_FACTOR = 2000;

    function execute() external {
        AaveV2Polygon.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(
            AaveV2PolygonAssets.CRV_UNDERLYING,
            INTEREST_RATE_STRATEGY
        );
        AaveV3Polygon.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(
            AaveV3PolygonAssets.CRV_UNDERLYING,
            INTEREST_RATE_STRATEGY_V3
        );
        AaveV3Polygon.POOL_CONFIGURATOR.setBorrowCap(AaveV3PolygonAssets.CRV_UNDERLYING, NEW_BORROW_CAP_V3);
        AaveV3Polygon.POOL_CONFIGURATOR.setSupplyCap(AaveV3PolygonAssets.CRV_UNDERLYING, NEW_SUPPLY_CAP_V3);
        AaveV3Polygon.POOL_CONFIGURATOR.setReserveFactor(AaveV3PolygonAssets.CRV_UNDERLYING, NEW_RESERVE_FACTOR);
    }
}
