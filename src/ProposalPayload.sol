// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {AaveMisc} from "@aave-address-book/AaveMisc.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";

/**
 * @title BAL Interest Rate Curve Upgrade
 * @author Llama
 * @notice Amend BAL interest rate parameters on the Aave Ethereum v2liquidity pool.
 * Governance Forum Post: https://governance.aave.com/t/arfc-bal-interest-rate-curve-upgrade/10484/10
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xceb72907ec281318c0271039c6cbde07d057e368aff8d8b75ad90389f64bf83c
 */
contract ProposalPayload {
    address public constant INTEREST_RATE_STRATEGY = address(0);
    address public constant BAL = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function executeMainnet() external {
        AaveV2Ethereum.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(BAL, INTEREST_RATE_STRATEGY);
    }
}
