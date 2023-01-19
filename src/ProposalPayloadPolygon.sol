// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {AaveMisc} from "@aave-address-book/AaveMisc.sol";
import {AaveV2Polygon} from "@aave-address-book/AaveV2Polygon.sol";
import {AaveV3Polygon} from "@aave-address-book/AaveV3Polygon.sol";

/**
 * @title BAL Interest Rate Curve Upgrade
 * @author Llama
 * @notice Amend BAL interest rate parameters on the Aave Polygon v2 and Aave Polygon v3 liquidity pools.
 * Governance Forum Post: https://governance.aave.com/t/arfc-bal-interest-rate-curve-upgrade/10484/10
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xceb72907ec281318c0271039c6cbde07d057e368aff8d8b75ad90389f64bf83c
 */
contract ProposalPayloadPolygon {
    address public constant INTEREST_RATE_STRATEGY_V3 = 0x4b8D3277d49E114C8F2D6E0B2eD310e29226fe16;
    address public constant INTEREST_RATE_STRATEGY = 0x80cb7e9E015C5331bF34e06de62443d070FD6654;
    address public constant BAL = 0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3;
    uint256 public constant NEW_BORROW_CAP_V3 = 256_140;

    /// @notice The AAVE governance executor calls this function to implement the proposal on Polygon.
    function execute() external {
        AaveV2Polygon.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(BAL, INTEREST_RATE_STRATEGY);
        AaveV3Polygon.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(BAL, INTEREST_RATE_STRATEGY_V3);
        AaveV3Polygon.POOL_CONFIGURATOR.setBorrowCap(BAL, NEW_BORROW_CAP_V3);
    }
}
