// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {AaveV2Polygon} from "aave-address-book/AaveV2Polygon.sol";
import {AaveV3Polygon} from "aave-address-book/AaveV3Polygon.sol";

/**
 * @title CRV Interest Rate Curve Upgrade
 * @author Llama
 * @notice Amend CRV interest rate parameters on the Aave Polygon v2 and Aave Polygon v3 liquidity pools, as well as borrow, supply cap and reserve factor for v3.
 * Governance Forum Post: https://governance.aave.com/t/arfc-crv-interest-rate-curve-upgrade/11337
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x2cb10cfb57a79bb97c3aed1cc3e9847227fb0f6a843916921ae315b9d8ad11d3
 */
contract ProposalPayloadPolygon {
    address public constant INTEREST_RATE_STRATEGY_V3 = 0x4b8D3277d49E114C8F2D6E0B2eD310e29226fe16;
    address public constant INTEREST_RATE_STRATEGY = 0x80cb7e9E015C5331bF34e06de62443d070FD6654;
    uint256 public constant NEW_BORROW_CAP_V3 = 900_190;
    uint256 public constant NEW_SUPPLY_CAP_V3 = 1_125_240;
    uint256 public constant NEW_RESERVE_FACTOR = 2000;

    /// @notice The AAVE governance executor calls this function to implement the proposal on Polygon.
    function execute() external {
        AaveV2Polygon.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(
            AaveV2Polygon.CRV_UNDERLYING,
            INTEREST_RATE_STRATEGY
        );
        AaveV3Polygon.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(
            AaveV2Polygon.CRV_UNDERLYING,
            INTEREST_RATE_STRATEGY_V3
        );
        AaveV3Polygon.POOL_CONFIGURATOR.setBorrowCap(AaveV2Polygon.CRV_UNDERLYING, NEW_BORROW_CAP_V3);
        AaveV3Polygon.POOL_CONFIGURATOR.setSupplyCap(AaveV2Polygon.CRV_UNDERLYING, NEW_SUPPLY_CAP_V3);
        AaveV3Polygon.POOL_CONFIGURATOR.setReserveFactor(AaveV2Polygon.CRV_UNDERLYING, NEW_RESERVE_FACTOR);
    }
}
