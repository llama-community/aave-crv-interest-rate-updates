// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";

/**
 * @title CRV Interest Rate Curve Upgrade
 * @author Llama
 * @notice Amend CRV interest rate parameters on the Aave Ethereum v2liquidity pool.
 * Governance Forum Post: https://governance.aave.com/t/arfc-crv-interest-rate-curve-upgrade/11337
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x2cb10cfb57a79bb97c3aed1cc3e9847227fb0f6a843916921ae315b9d8ad11d3
 */
contract ProposalPayload {
    address public constant INTEREST_RATE_STRATEGY = 0x04c28D6fE897859153eA753f986cc249Bf064f71;
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        AaveV2Ethereum.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(CRV, INTEREST_RATE_STRATEGY);
    }
}
