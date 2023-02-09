```diff
diff --git a/./src/etherscan/polygon_0x9025C2d672afA29f43cB59b3035CaCfC401F5D62/Flattened.sol b/./src/etherscan/polygon_0x0294920FaA5a021a63A7056611Be1beBc7C5A028/Flattened.sol
index b0fdc42..809beb9 100644
--- a/./src/etherscan/polygon_0x9025C2d672afA29f43cB59b3035CaCfC401F5D62/Flattened.sol
+++ b/./src/etherscan/polygon_0x0294920FaA5a021a63A7056611Be1beBc7C5A028/Flattened.sol
@@ -1,7 +1,3 @@
-// Sources flattened with hardhat v2.6.5 https://hardhat.org
-
-// File contracts/dependencies/openzeppelin/contracts/SafeMath.sol
-
 // SPDX-License-Identifier: agpl-3.0
 pragma solidity 0.6.12;

@@ -166,10 +162,6 @@ library SafeMath {
   }
 }

-
-// File contracts/interfaces/IReserveInterestRateStrategy.sol
-
-
 /**
  * @title IReserveInterestRateStrategyInterface interface
  * @dev Interface for the calculation of the interest rates
@@ -215,10 +207,6 @@ interface IReserveInterestRateStrategy {
     );
 }

-
-// File contracts/protocol/libraries/helpers/Errors.sol
-
-
 /**
  * @title Errors library
  * @author Aave
@@ -336,10 +324,6 @@ library Errors {
   }
 }

-
-// File contracts/protocol/libraries/math/WadRayMath.sol
-
-
 /**
  * @title WadRayMath library
  * @author Aave
@@ -471,10 +455,6 @@ library WadRayMath {
   }
 }

-
-// File contracts/protocol/libraries/math/PercentageMath.sol
-
-
 /**
  * @title PercentageMath library
  * @author Aave
@@ -525,10 +505,6 @@ library PercentageMath {
   }
 }

-
-// File contracts/interfaces/ILendingPoolAddressesProvider.sol
-
-
 /**
  * @title LendingPoolAddressesProvider contract
  * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
@@ -587,10 +563,6 @@ interface ILendingPoolAddressesProvider {
   function setLendingRateOracle(address lendingRateOracle) external;
 }

-
-// File contracts/interfaces/ILendingRateOracle.sol
-
-
 /**
  * @title ILendingRateOracle interface
  * @notice Interface for the Aave borrow rate oracle. Provides the average market borrow rate to be used as a base for the stable borrow rate calculations
@@ -608,10 +580,6 @@ interface ILendingRateOracle {
   function setMarketBorrowRate(address asset, uint256 rate) external;
 }

-
-// File contracts/dependencies/openzeppelin/contracts/IERC20.sol
-
-
 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
  */
@@ -690,16 +658,6 @@ interface IERC20 {
   event Approval(address indexed owner, address indexed spender, uint256 value);
 }

-
-// File contracts/protocol/lendingpool/DefaultReserveInterestRateStrategy.sol
-
-
-
-
-
-
-
-
 /**
  * @title DefaultReserveInterestRateStrategy contract
  * @notice Implements the calculation of the interest rates depending on the reserve state
```
