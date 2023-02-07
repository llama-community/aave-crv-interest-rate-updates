// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {AaveV2Polygon, AaveV2PolygonAssets} from "aave-address-book/AaveV2Polygon.sol";
import {AaveV3Polygon} from "aave-address-book/AaveV3Polygon.sol";

/**
 * @title CRV Interest Rate Curve Upgrade
 * @author Llama
 * @notice Amend CRV interest rate parameters on the Aave Polygon v2 and Aave Polygon v3 liquidity pools, as well as borrow, supply cap and reserve factor for v3.
 * Governance Forum Post: https://governance.aave.com/t/arfc-crv-interest-rate-curve-upgrade/11337
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x2cb10cfb57a79bb97c3aed1cc3e9847227fb0f6a843916921ae315b9d8ad11d3
 */
contract ProposalPayloadPolygon {
    address public constant INTEREST_RATE_STRATEGY_V3 = 0x04c28D6fE897859153eA753f986cc249Bf064f71;
    address public constant INTEREST_RATE_STRATEGY = 0x0294920FaA5a021a63A7056611Be1beBc7C5A028;
    uint256 public constant NEW_BORROW_CAP_V3 = 900_190;
    uint256 public constant NEW_SUPPLY_CAP_V3 = 1_125_240;
    uint256 public constant NEW_RESERVE_FACTOR = 2000;

    /// @notice The AAVE governance executor calls this function to implement the proposal on Polygon.
    function execute() external {
        AaveV2Polygon.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(
            AaveV2PolygonAssets.CRV_UNDERLYING,
            INTEREST_RATE_STRATEGY
        );
        AaveV3Polygon.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(
            AaveV2PolygonAssets.CRV_UNDERLYING,
            INTEREST_RATE_STRATEGY_V3
        );
        AaveV3Polygon.POOL_CONFIGURATOR.setBorrowCap(AaveV2PolygonAssets.CRV_UNDERLYING, NEW_BORROW_CAP_V3);
        AaveV3Polygon.POOL_CONFIGURATOR.setSupplyCap(AaveV2PolygonAssets.CRV_UNDERLYING, NEW_SUPPLY_CAP_V3);
        AaveV3Polygon.POOL_CONFIGURATOR.setReserveFactor(AaveV2PolygonAssets.CRV_UNDERLYING, NEW_RESERVE_FACTOR);
    }
}
