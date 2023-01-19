// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct Token {
  address underlyingAsset;
  address aTokenAddress;
  address stableDebtTokenAddress;
  address variableDebtTokenAddress;
}
