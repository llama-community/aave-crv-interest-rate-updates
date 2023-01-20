// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {AaveMisc} from "@aave-address-book/AaveMisc.sol";
import {AaveV2Polygon} from "@aave-address-book/AaveV2Polygon.sol";
import {AaveV3Polygon} from "@aave-address-book/AaveV3Polygon.sol";

/**
 * @title CRV Interest Rate Curve Upgrade
 * @author Llama
 * @notice Amend CRV interest rate parameters on the Aave Polygon v2 and Aave Polygon v3 liquidity pools.
 * Governance Forum Post: https://governance.aave.com/t/arfc-crv-interest-rate-curve-upgrade/11337
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x2cb10cfb57a79bb97c3aed1cc3e9847227fb0f6a843916921ae315b9d8ad11d3
 */
contract ProposalPayloadPolygon {
    address public constant INTEREST_RATE_STRATEGY_V3 = 0x4b8D3277d49E114C8F2D6E0B2eD310e29226fe16;
    address public constant INTEREST_RATE_STRATEGY = 0x80cb7e9E015C5331bF34e06de62443d070FD6654;
    address public constant CRV = 0x172370d5Cd63279eFa6d502DAB29171933a610AF;
    uint256 public constant NEW_BORROW_CAP_V3 = 1_012_720;
    uint256 public constant NEW_SUPPLY_CAP_V3 = 1_125_240;
    uint256 public constant NEW_RESERVE_FACTOR = 2000;

    /// @notice The AAVE governance executor calls this function to implement the proposal on Polygon.
    function execute() external {
        AaveV2Polygon.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(CRV, INTEREST_RATE_STRATEGY);
        AaveV3Polygon.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(CRV, INTEREST_RATE_STRATEGY_V3);
        AaveV3Polygon.POOL_CONFIGURATOR.setBorrowCap(CRV, NEW_BORROW_CAP_V3);
        AaveV3Polygon.POOL_CONFIGURATOR.setSupplyCap(CRV, NEW_SUPPLY_CAP_V3);
        AaveV3Polygon.POOL_CONFIGURATOR.setReserveFactor(CRV, NEW_RESERVE_FACTOR);
    }
}
