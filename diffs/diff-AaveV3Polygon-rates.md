```diff
diff --git a/./src/etherscan/polygon_0x03733F4E008d36f2e37F0080fF1c8DF756622E6F/Flattened.sol b/./src/etherscan/polygon_0xBefcd01681224555b74eAC87207eaF9Bc3361F59/Flattened.sol
index 2c97dab..bb9060a 100644
--- a/./src/etherscan/polygon_0x03733F4E008d36f2e37F0080fF1c8DF756622E6F/Flattened.sol
+++ b/./src/etherscan/polygon_0xBefcd01681224555b74eAC87207eaF9Bc3361F59/Flattened.sol
@@ -1,5 +1,5 @@
 // SPDX-License-Identifier: BUSL-1.1
-pragma solidity 0.8.10;
+pragma solidity ^0.8.0;

 /**
  * @dev Interface of the ERC20 standard as defined in the EIP.
@@ -86,7 +86,7 @@ interface IERC20 {
  * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
  * with 27 digits of precision)
  * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
- **/
+ */
 library WadRayMath {
   // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
   uint256 internal constant WAD = 1e18;
@@ -103,7 +103,7 @@ library WadRayMath {
    * @param a Wad
    * @param b Wad
    * @return c = a*b, in wad
-   **/
+   */
   function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
     assembly {
@@ -121,7 +121,7 @@ library WadRayMath {
    * @param a Wad
    * @param b Wad
    * @return c = a/b, in wad
-   **/
+   */
   function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
     // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
     assembly {
@@ -139,7 +139,7 @@ library WadRayMath {
    * @param a Ray
    * @param b Ray
    * @return c = a raymul b
-   **/
+   */
   function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
     assembly {
@@ -157,7 +157,7 @@ library WadRayMath {
    * @param a Ray
    * @param b Ray
    * @return c = a raydiv b
-   **/
+   */
   function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
     // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
     assembly {
@@ -174,7 +174,7 @@ library WadRayMath {
    * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
    * @param a Ray
    * @return b = a converted to wad, rounded half up to the nearest wad
-   **/
+   */
   function rayToWad(uint256 a) internal pure returns (uint256 b) {
     assembly {
       b := div(a, WAD_RAY_RATIO)
@@ -190,7 +190,7 @@ library WadRayMath {
    * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
    * @param a Wad
    * @return b = a converted in ray
-   **/
+   */
   function wadToRay(uint256 a) internal pure returns (uint256 b) {
     // to avoid overflow, b/WAD_RAY_RATIO == a
     assembly {
@@ -209,7 +209,7 @@ library WadRayMath {
  * @notice Provides functions to perform percentage calculations
  * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
  * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
- **/
+ */
 library PercentageMath {
   // Maximum percentage factor (100.00%)
   uint256 internal constant PERCENTAGE_FACTOR = 1e4;
@@ -223,7 +223,7 @@ library PercentageMath {
    * @param value The value of which the percentage needs to be calculated
    * @param percentage The percentage of the value to be calculated
    * @return result value percentmul percentage
-   **/
+   */
   function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
     // to avoid overflow, value <= (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
     assembly {
@@ -246,7 +246,7 @@ library PercentageMath {
    * @param value The value of which the percentage needs to be calculated
    * @param percentage The percentage of the value to be calculated
    * @return result value percentdiv percentage
-   **/
+   */
   function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
     // to avoid overflow, value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR
     assembly {
@@ -528,31 +528,117 @@ library DataTypes {
   }
 }

+/**
+ * @title Errors library
+ * @author Aave
+ * @notice Defines the error messages emitted by the different contracts of the Aave protocol
+ */
+library Errors {
+  string public constant CALLER_NOT_POOL_ADMIN = '1'; // 'The caller of the function is not a pool admin'
+  string public constant CALLER_NOT_EMERGENCY_ADMIN = '2'; // 'The caller of the function is not an emergency admin'
+  string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = '3'; // 'The caller of the function is not a pool or emergency admin'
+  string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = '4'; // 'The caller of the function is not a risk or pool admin'
+  string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = '5'; // 'The caller of the function is not an asset listing or pool admin'
+  string public constant CALLER_NOT_BRIDGE = '6'; // 'The caller of the function is not a bridge'
+  string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = '7'; // 'Pool addresses provider is not registered'
+  string public constant INVALID_ADDRESSES_PROVIDER_ID = '8'; // 'Invalid id for the pool addresses provider'
+  string public constant NOT_CONTRACT = '9'; // 'Address is not a contract'
+  string public constant CALLER_NOT_POOL_CONFIGURATOR = '10'; // 'The caller of the function is not the pool configurator'
+  string public constant CALLER_NOT_ATOKEN = '11'; // 'The caller of the function is not an AToken'
+  string public constant INVALID_ADDRESSES_PROVIDER = '12'; // 'The address of the pool addresses provider is invalid'
+  string public constant INVALID_FLASHLOAN_EXECUTOR_RETURN = '13'; // 'Invalid return value of the flashloan executor function'
+  string public constant RESERVE_ALREADY_ADDED = '14'; // 'Reserve has already been added to reserve list'
+  string public constant NO_MORE_RESERVES_ALLOWED = '15'; // 'Maximum amount of reserves in the pool reached'
+  string public constant EMODE_CATEGORY_RESERVED = '16'; // 'Zero eMode category is reserved for volatile heterogeneous assets'
+  string public constant INVALID_EMODE_CATEGORY_ASSIGNMENT = '17'; // 'Invalid eMode category assignment to asset'
+  string public constant RESERVE_LIQUIDITY_NOT_ZERO = '18'; // 'The liquidity of the reserve needs to be 0'
+  string public constant FLASHLOAN_PREMIUM_INVALID = '19'; // 'Invalid flashloan premium'
+  string public constant INVALID_RESERVE_PARAMS = '20'; // 'Invalid risk parameters for the reserve'
+  string public constant INVALID_EMODE_CATEGORY_PARAMS = '21'; // 'Invalid risk parameters for the eMode category'
+  string public constant BRIDGE_PROTOCOL_FEE_INVALID = '22'; // 'Invalid bridge protocol fee'
+  string public constant CALLER_MUST_BE_POOL = '23'; // 'The caller of this function must be a pool'
+  string public constant INVALID_MINT_AMOUNT = '24'; // 'Invalid amount to mint'
+  string public constant INVALID_BURN_AMOUNT = '25'; // 'Invalid amount to burn'
+  string public constant INVALID_AMOUNT = '26'; // 'Amount must be greater than 0'
+  string public constant RESERVE_INACTIVE = '27'; // 'Action requires an active reserve'
+  string public constant RESERVE_FROZEN = '28'; // 'Action cannot be performed because the reserve is frozen'
+  string public constant RESERVE_PAUSED = '29'; // 'Action cannot be performed because the reserve is paused'
+  string public constant BORROWING_NOT_ENABLED = '30'; // 'Borrowing is not enabled'
+  string public constant STABLE_BORROWING_NOT_ENABLED = '31'; // 'Stable borrowing is not enabled'
+  string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = '32'; // 'User cannot withdraw more than the available balance'
+  string public constant INVALID_INTEREST_RATE_MODE_SELECTED = '33'; // 'Invalid interest rate mode selected'
+  string public constant COLLATERAL_BALANCE_IS_ZERO = '34'; // 'The collateral balance is 0'
+  string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '35'; // 'Health factor is lesser than the liquidation threshold'
+  string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = '36'; // 'There is not enough collateral to cover a new borrow'
+  string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = '37'; // 'Collateral is (mostly) the same currency that is being borrowed'
+  string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '38'; // 'The requested amount is greater than the max loan size in stable rate mode'
+  string public constant NO_DEBT_OF_SELECTED_TYPE = '39'; // 'For repayment of a specific type of debt, the user needs to have debt that type'
+  string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '40'; // 'To repay on behalf of a user an explicit amount to repay is needed'
+  string public constant NO_OUTSTANDING_STABLE_DEBT = '41'; // 'User does not have outstanding stable rate debt on this reserve'
+  string public constant NO_OUTSTANDING_VARIABLE_DEBT = '42'; // 'User does not have outstanding variable rate debt on this reserve'
+  string public constant UNDERLYING_BALANCE_ZERO = '43'; // 'The underlying balance needs to be greater than 0'
+  string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '44'; // 'Interest rate rebalance conditions were not met'
+  string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '45'; // 'Health factor is not below the threshold'
+  string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = '46'; // 'The collateral chosen cannot be liquidated'
+  string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '47'; // 'User did not borrow the specified currency'
+  string public constant INCONSISTENT_FLASHLOAN_PARAMS = '49'; // 'Inconsistent flashloan parameters'
+  string public constant BORROW_CAP_EXCEEDED = '50'; // 'Borrow cap is exceeded'
+  string public constant SUPPLY_CAP_EXCEEDED = '51'; // 'Supply cap is exceeded'
+  string public constant UNBACKED_MINT_CAP_EXCEEDED = '52'; // 'Unbacked mint cap is exceeded'
+  string public constant DEBT_CEILING_EXCEEDED = '53'; // 'Debt ceiling is exceeded'
+  string public constant UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO = '54'; // 'Claimable rights over underlying not zero (aToken supply or accruedToTreasury)'
+  string public constant STABLE_DEBT_NOT_ZERO = '55'; // 'Stable debt supply is not zero'
+  string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = '56'; // 'Variable debt supply is not zero'
+  string public constant LTV_VALIDATION_FAILED = '57'; // 'Ltv validation failed'
+  string public constant INCONSISTENT_EMODE_CATEGORY = '58'; // 'Inconsistent eMode category'
+  string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = '59'; // 'Price oracle sentinel validation failed'
+  string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION = '60'; // 'Asset is not borrowable in isolation mode'
+  string public constant RESERVE_ALREADY_INITIALIZED = '61'; // 'Reserve has already been initialized'
+  string public constant USER_IN_ISOLATION_MODE = '62'; // 'User is in isolation mode'
+  string public constant INVALID_LTV = '63'; // 'Invalid ltv parameter for the reserve'
+  string public constant INVALID_LIQ_THRESHOLD = '64'; // 'Invalid liquidity threshold parameter for the reserve'
+  string public constant INVALID_LIQ_BONUS = '65'; // 'Invalid liquidity bonus parameter for the reserve'
+  string public constant INVALID_DECIMALS = '66'; // 'Invalid decimals parameter of the underlying asset of the reserve'
+  string public constant INVALID_RESERVE_FACTOR = '67'; // 'Invalid reserve factor parameter for the reserve'
+  string public constant INVALID_BORROW_CAP = '68'; // 'Invalid borrow cap for the reserve'
+  string public constant INVALID_SUPPLY_CAP = '69'; // 'Invalid supply cap for the reserve'
+  string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = '70'; // 'Invalid liquidation protocol fee for the reserve'
+  string public constant INVALID_EMODE_CATEGORY = '71'; // 'Invalid eMode category for the reserve'
+  string public constant INVALID_UNBACKED_MINT_CAP = '72'; // 'Invalid unbacked mint cap for the reserve'
+  string public constant INVALID_DEBT_CEILING = '73'; // 'Invalid debt ceiling for the reserve
+  string public constant INVALID_RESERVE_INDEX = '74'; // 'Invalid reserve index'
+  string public constant ACL_ADMIN_CANNOT_BE_ZERO = '75'; // 'ACL admin cannot be set to the zero address'
+  string public constant INCONSISTENT_PARAMS_LENGTH = '76'; // 'Array parameters that should be equal length are not'
+  string public constant ZERO_ADDRESS_NOT_VALID = '77'; // 'Zero address not valid'
+  string public constant INVALID_EXPIRATION = '78'; // 'Invalid expiration'
+  string public constant INVALID_SIGNATURE = '79'; // 'Invalid signature'
+  string public constant OPERATION_NOT_SUPPORTED = '80'; // 'Operation not supported'
+  string public constant DEBT_CEILING_NOT_ZERO = '81'; // 'Debt ceiling is not zero'
+  string public constant ASSET_NOT_LISTED = '82'; // 'Asset is not listed'
+  string public constant INVALID_OPTIMAL_USAGE_RATIO = '83'; // 'Invalid optimal usage ratio'
+  string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = '84'; // 'Invalid optimal stable to total debt ratio'
+  string public constant UNDERLYING_CANNOT_BE_RESCUED = '85'; // 'The underlying asset cannot be rescued'
+  string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = '86'; // 'Reserve has already been added to reserve list'
+  string public constant POOL_ADDRESSES_DO_NOT_MATCH = '87'; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
+  string public constant STABLE_BORROWING_ENABLED = '88'; // 'Stable borrowing is enabled'
+  string public constant SILOED_BORROWING_VIOLATION = '89'; // 'User is trying to borrow multiple assets including a siloed one'
+  string public constant RESERVE_DEBT_NOT_ZERO = '90'; // the total debt of the reserve needs to be 0
+  string public constant FLASHLOAN_DISABLED = '91'; // FlashLoaning for this asset is disabled
+}
+
 /**
  * @title IReserveInterestRateStrategy
  * @author Aave
  * @notice Interface for the calculation of the interest rates
  */
 interface IReserveInterestRateStrategy {
-  /**
-   * @notice Returns the base variable borrow rate
-   * @return The base variable borrow rate, expressed in ray
-   **/
-  function getBaseVariableBorrowRate() external view returns (uint256);
-
-  /**
-   * @notice Returns the maximum variable borrow rate
-   * @return The maximum variable borrow rate, expressed in ray
-   **/
-  function getMaxVariableBorrowRate() external view returns (uint256);
-
   /**
    * @notice Calculates the interest rates depending on the reserve's state and configurations
    * @param params The parameters needed to calculate interest rates
    * @return liquidityRate The liquidity rate expressed in rays
    * @return stableBorrowRate The stable borrow rate expressed in rays
    * @return variableBorrowRate The variable borrow rate expressed in rays
-   **/
+   */
   function calculateInterestRates(DataTypes.CalculateInterestRatesParams memory params)
     external
     view
@@ -567,7 +653,7 @@ interface IReserveInterestRateStrategy {
  * @title IPoolAddressesProvider
  * @author Aave
  * @notice Defines the basic interface for a Pool Addresses Provider.
- **/
+ */
 interface IPoolAddressesProvider {
   /**
    * @dev Emitted when the market identifier is updated.
@@ -662,7 +748,7 @@ interface IPoolAddressesProvider {
   /**
    * @notice Returns the id of the Aave market to which this contract points to.
    * @return The market id
-   **/
+   */
   function getMarketId() external view returns (string memory);

   /**
@@ -704,27 +790,27 @@ interface IPoolAddressesProvider {
   /**
    * @notice Returns the address of the Pool proxy.
    * @return The Pool proxy address
-   **/
+   */
   function getPool() external view returns (address);

   /**
    * @notice Updates the implementation of the Pool, or creates a proxy
    * setting the new `pool` implementation when the function is called for the first time.
    * @param newPoolImpl The new Pool implementation
-   **/
+   */
   function setPoolImpl(address newPoolImpl) external;

   /**
    * @notice Returns the address of the PoolConfigurator proxy.
    * @return The PoolConfigurator proxy address
-   **/
+   */
   function getPoolConfigurator() external view returns (address);

   /**
    * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
    * setting the new `PoolConfigurator` implementation when the function is called for the first time.
    * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
-   **/
+   */
   function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

   /**
@@ -748,7 +834,7 @@ interface IPoolAddressesProvider {
   /**
    * @notice Updates the address of the ACL manager.
    * @param newAclManager The address of the new ACLManager
-   **/
+   */
   function setACLManager(address newAclManager) external;

   /**
@@ -772,7 +858,7 @@ interface IPoolAddressesProvider {
   /**
    * @notice Updates the address of the price oracle sentinel.
    * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
-   **/
+   */
   function setPriceOracleSentinel(address newPriceOracleSentinel) external;

   /**
@@ -784,106 +870,100 @@ interface IPoolAddressesProvider {
   /**
    * @notice Updates the address of the data provider.
    * @param newDataProvider The address of the new DataProvider
-   **/
+   */
   function setPoolDataProvider(address newDataProvider) external;
 }

 /**
- * @title Errors library
+ * @title IDefaultInterestRateStrategy
  * @author Aave
- * @notice Defines the error messages emitted by the different contracts of the Aave protocol
+ * @notice Defines the basic interface of the DefaultReserveInterestRateStrategy
  */
-library Errors {
-  string public constant CALLER_NOT_POOL_ADMIN = '1'; // 'The caller of the function is not a pool admin'
-  string public constant CALLER_NOT_EMERGENCY_ADMIN = '2'; // 'The caller of the function is not an emergency admin'
-  string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = '3'; // 'The caller of the function is not a pool or emergency admin'
-  string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = '4'; // 'The caller of the function is not a risk or pool admin'
-  string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = '5'; // 'The caller of the function is not an asset listing or pool admin'
-  string public constant CALLER_NOT_BRIDGE = '6'; // 'The caller of the function is not a bridge'
-  string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = '7'; // 'Pool addresses provider is not registered'
-  string public constant INVALID_ADDRESSES_PROVIDER_ID = '8'; // 'Invalid id for the pool addresses provider'
-  string public constant NOT_CONTRACT = '9'; // 'Address is not a contract'
-  string public constant CALLER_NOT_POOL_CONFIGURATOR = '10'; // 'The caller of the function is not the pool configurator'
-  string public constant CALLER_NOT_ATOKEN = '11'; // 'The caller of the function is not an AToken'
-  string public constant INVALID_ADDRESSES_PROVIDER = '12'; // 'The address of the pool addresses provider is invalid'
-  string public constant INVALID_FLASHLOAN_EXECUTOR_RETURN = '13'; // 'Invalid return value of the flashloan executor function'
-  string public constant RESERVE_ALREADY_ADDED = '14'; // 'Reserve has already been added to reserve list'
-  string public constant NO_MORE_RESERVES_ALLOWED = '15'; // 'Maximum amount of reserves in the pool reached'
-  string public constant EMODE_CATEGORY_RESERVED = '16'; // 'Zero eMode category is reserved for volatile heterogeneous assets'
-  string public constant INVALID_EMODE_CATEGORY_ASSIGNMENT = '17'; // 'Invalid eMode category assignment to asset'
-  string public constant RESERVE_LIQUIDITY_NOT_ZERO = '18'; // 'The liquidity of the reserve needs to be 0'
-  string public constant FLASHLOAN_PREMIUM_INVALID = '19'; // 'Invalid flashloan premium'
-  string public constant INVALID_RESERVE_PARAMS = '20'; // 'Invalid risk parameters for the reserve'
-  string public constant INVALID_EMODE_CATEGORY_PARAMS = '21'; // 'Invalid risk parameters for the eMode category'
-  string public constant BRIDGE_PROTOCOL_FEE_INVALID = '22'; // 'Invalid bridge protocol fee'
-  string public constant CALLER_MUST_BE_POOL = '23'; // 'The caller of this function must be a pool'
-  string public constant INVALID_MINT_AMOUNT = '24'; // 'Invalid amount to mint'
-  string public constant INVALID_BURN_AMOUNT = '25'; // 'Invalid amount to burn'
-  string public constant INVALID_AMOUNT = '26'; // 'Amount must be greater than 0'
-  string public constant RESERVE_INACTIVE = '27'; // 'Action requires an active reserve'
-  string public constant RESERVE_FROZEN = '28'; // 'Action cannot be performed because the reserve is frozen'
-  string public constant RESERVE_PAUSED = '29'; // 'Action cannot be performed because the reserve is paused'
-  string public constant BORROWING_NOT_ENABLED = '30'; // 'Borrowing is not enabled'
-  string public constant STABLE_BORROWING_NOT_ENABLED = '31'; // 'Stable borrowing is not enabled'
-  string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = '32'; // 'User cannot withdraw more than the available balance'
-  string public constant INVALID_INTEREST_RATE_MODE_SELECTED = '33'; // 'Invalid interest rate mode selected'
-  string public constant COLLATERAL_BALANCE_IS_ZERO = '34'; // 'The collateral balance is 0'
-  string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '35'; // 'Health factor is lesser than the liquidation threshold'
-  string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = '36'; // 'There is not enough collateral to cover a new borrow'
-  string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = '37'; // 'Collateral is (mostly) the same currency that is being borrowed'
-  string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '38'; // 'The requested amount is greater than the max loan size in stable rate mode'
-  string public constant NO_DEBT_OF_SELECTED_TYPE = '39'; // 'For repayment of a specific type of debt, the user needs to have debt that type'
-  string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '40'; // 'To repay on behalf of a user an explicit amount to repay is needed'
-  string public constant NO_OUTSTANDING_STABLE_DEBT = '41'; // 'User does not have outstanding stable rate debt on this reserve'
-  string public constant NO_OUTSTANDING_VARIABLE_DEBT = '42'; // 'User does not have outstanding variable rate debt on this reserve'
-  string public constant UNDERLYING_BALANCE_ZERO = '43'; // 'The underlying balance needs to be greater than 0'
-  string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '44'; // 'Interest rate rebalance conditions were not met'
-  string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '45'; // 'Health factor is not below the threshold'
-  string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = '46'; // 'The collateral chosen cannot be liquidated'
-  string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '47'; // 'User did not borrow the specified currency'
-  string public constant SAME_BLOCK_BORROW_REPAY = '48'; // 'Borrow and repay in same block is not allowed'
-  string public constant INCONSISTENT_FLASHLOAN_PARAMS = '49'; // 'Inconsistent flashloan parameters'
-  string public constant BORROW_CAP_EXCEEDED = '50'; // 'Borrow cap is exceeded'
-  string public constant SUPPLY_CAP_EXCEEDED = '51'; // 'Supply cap is exceeded'
-  string public constant UNBACKED_MINT_CAP_EXCEEDED = '52'; // 'Unbacked mint cap is exceeded'
-  string public constant DEBT_CEILING_EXCEEDED = '53'; // 'Debt ceiling is exceeded'
-  string public constant ATOKEN_SUPPLY_NOT_ZERO = '54'; // 'AToken supply is not zero'
-  string public constant STABLE_DEBT_NOT_ZERO = '55'; // 'Stable debt supply is not zero'
-  string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = '56'; // 'Variable debt supply is not zero'
-  string public constant LTV_VALIDATION_FAILED = '57'; // 'Ltv validation failed'
-  string public constant INCONSISTENT_EMODE_CATEGORY = '58'; // 'Inconsistent eMode category'
-  string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = '59'; // 'Price oracle sentinel validation failed'
-  string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION = '60'; // 'Asset is not borrowable in isolation mode'
-  string public constant RESERVE_ALREADY_INITIALIZED = '61'; // 'Reserve has already been initialized'
-  string public constant USER_IN_ISOLATION_MODE = '62'; // 'User is in isolation mode'
-  string public constant INVALID_LTV = '63'; // 'Invalid ltv parameter for the reserve'
-  string public constant INVALID_LIQ_THRESHOLD = '64'; // 'Invalid liquidity threshold parameter for the reserve'
-  string public constant INVALID_LIQ_BONUS = '65'; // 'Invalid liquidity bonus parameter for the reserve'
-  string public constant INVALID_DECIMALS = '66'; // 'Invalid decimals parameter of the underlying asset of the reserve'
-  string public constant INVALID_RESERVE_FACTOR = '67'; // 'Invalid reserve factor parameter for the reserve'
-  string public constant INVALID_BORROW_CAP = '68'; // 'Invalid borrow cap for the reserve'
-  string public constant INVALID_SUPPLY_CAP = '69'; // 'Invalid supply cap for the reserve'
-  string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = '70'; // 'Invalid liquidation protocol fee for the reserve'
-  string public constant INVALID_EMODE_CATEGORY = '71'; // 'Invalid eMode category for the reserve'
-  string public constant INVALID_UNBACKED_MINT_CAP = '72'; // 'Invalid unbacked mint cap for the reserve'
-  string public constant INVALID_DEBT_CEILING = '73'; // 'Invalid debt ceiling for the reserve
-  string public constant INVALID_RESERVE_INDEX = '74'; // 'Invalid reserve index'
-  string public constant ACL_ADMIN_CANNOT_BE_ZERO = '75'; // 'ACL admin cannot be set to the zero address'
-  string public constant INCONSISTENT_PARAMS_LENGTH = '76'; // 'Array parameters that should be equal length are not'
-  string public constant ZERO_ADDRESS_NOT_VALID = '77'; // 'Zero address not valid'
-  string public constant INVALID_EXPIRATION = '78'; // 'Invalid expiration'
-  string public constant INVALID_SIGNATURE = '79'; // 'Invalid signature'
-  string public constant OPERATION_NOT_SUPPORTED = '80'; // 'Operation not supported'
-  string public constant DEBT_CEILING_NOT_ZERO = '81'; // 'Debt ceiling is not zero'
-  string public constant ASSET_NOT_LISTED = '82'; // 'Asset is not listed'
-  string public constant INVALID_OPTIMAL_USAGE_RATIO = '83'; // 'Invalid optimal usage ratio'
-  string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = '84'; // 'Invalid optimal stable to total debt ratio'
-  string public constant UNDERLYING_CANNOT_BE_RESCUED = '85'; // 'The underlying asset cannot be rescued'
-  string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = '86'; // 'Reserve has already been added to reserve list'
-  string public constant POOL_ADDRESSES_DO_NOT_MATCH = '87'; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
-  string public constant STABLE_BORROWING_ENABLED = '88'; // 'Stable borrowing is enabled'
-  string public constant SILOED_BORROWING_VIOLATION = '89'; // 'User is trying to borrow multiple assets including a siloed one'
-  string public constant RESERVE_DEBT_NOT_ZERO = '90'; // the total debt of the reserve needs to be 0
+interface IDefaultInterestRateStrategy is IReserveInterestRateStrategy {
+  /**
+   * @notice Returns the usage ratio at which the pool aims to obtain most competitive borrow rates.
+   * @return The optimal usage ratio, expressed in ray.
+   */
+  function OPTIMAL_USAGE_RATIO() external view returns (uint256);
+
+  /**
+   * @notice Returns the optimal stable to total debt ratio of the reserve.
+   * @return The optimal stable to total debt ratio, expressed in ray.
+   */
+  function OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);
+
+  /**
+   * @notice Returns the excess usage ratio above the optimal.
+   * @dev It's always equal to 1-optimal usage ratio (added as constant for gas optimizations)
+   * @return The max excess usage ratio, expressed in ray.
+   */
+  function MAX_EXCESS_USAGE_RATIO() external view returns (uint256);
+
+  /**
+   * @notice Returns the excess stable debt ratio above the optimal.
+   * @dev It's always equal to 1-optimal stable to total debt ratio (added as constant for gas optimizations)
+   * @return The max excess stable to total debt ratio, expressed in ray.
+   */
+  function MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);
+
+  /**
+   * @notice Returns the address of the PoolAddressesProvider
+   * @return The address of the PoolAddressesProvider contract
+   */
+  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);
+
+  /**
+   * @notice Returns the variable rate slope below optimal usage ratio
+   * @dev It's the variable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
+   * @return The variable rate slope, expressed in ray
+   */
+  function getVariableRateSlope1() external view returns (uint256);
+
+  /**
+   * @notice Returns the variable rate slope above optimal usage ratio
+   * @dev It's the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
+   * @return The variable rate slope, expressed in ray
+   */
+  function getVariableRateSlope2() external view returns (uint256);
+
+  /**
+   * @notice Returns the stable rate slope below optimal usage ratio
+   * @dev It's the stable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
+   * @return The stable rate slope, expressed in ray
+   */
+  function getStableRateSlope1() external view returns (uint256);
+
+  /**
+   * @notice Returns the stable rate slope above optimal usage ratio
+   * @dev It's the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
+   * @return The stable rate slope, expressed in ray
+   */
+  function getStableRateSlope2() external view returns (uint256);
+
+  /**
+   * @notice Returns the stable rate excess offset
+   * @dev It's an additional premium applied to the stable when stable debt > OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO
+   * @return The stable rate excess offset, expressed in ray
+   */
+  function getStableRateExcessOffset() external view returns (uint256);
+
+  /**
+   * @notice Returns the base stable borrow rate
+   * @return The base stable borrow rate, expressed in ray
+   */
+  function getBaseStableBorrowRate() external view returns (uint256);
+
+  /**
+   * @notice Returns the base variable borrow rate
+   * @return The base variable borrow rate, expressed in ray
+   */
+  function getBaseVariableBorrowRate() external view returns (uint256);
+
+  /**
+   * @notice Returns the maximum variable borrow rate
+   * @return The maximum variable borrow rate, expressed in ray
+   */
+  function getMaxVariableBorrowRate() external view returns (uint256);
 }

 /**
@@ -894,35 +974,21 @@ library Errors {
  * point of usage and another from that one to 100%.
  * - An instance of this same contract, can't be used across different Aave markets, due to the caching
  *   of the PoolAddressesProvider
- **/
-contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
+ */
+contract DefaultReserveInterestRateStrategy is IDefaultInterestRateStrategy {
   using WadRayMath for uint256;
   using PercentageMath for uint256;

-  /**
-   * @dev This constant represents the usage ratio at which the pool aims to obtain most competitive borrow rates.
-   * Expressed in ray
-   **/
+  /// @inheritdoc IDefaultInterestRateStrategy
   uint256 public immutable OPTIMAL_USAGE_RATIO;

-  /**
-   * @dev This constant represents the optimal stable debt to total debt ratio of the reserve.
-   * Expressed in ray
-   */
+  /// @inheritdoc IDefaultInterestRateStrategy
   uint256 public immutable OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO;

-  /**
-   * @dev This constant represents the excess usage ratio above the optimal. It's always equal to
-   * 1-optimal usage ratio. Added as a constant here for gas optimizations.
-   * Expressed in ray
-   **/
+  /// @inheritdoc IDefaultInterestRateStrategy
   uint256 public immutable MAX_EXCESS_USAGE_RATIO;

-  /**
-   * @dev This constant represents the excess stable debt ratio above the optimal. It's always equal to
-   * 1-optimal stable to total debt ratio. Added as a constant here for gas optimizations.
-   * Expressed in ray
-   **/
+  /// @inheritdoc IDefaultInterestRateStrategy
   uint256 public immutable MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO;

   IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
@@ -992,65 +1058,42 @@ contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
     _stableRateExcessOffset = stableRateExcessOffset;
   }

-  /**
-   * @notice Returns the variable rate slope below optimal usage ratio
-   * @dev Its the variable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
-   * @return The variable rate slope
-   **/
+  /// @inheritdoc IDefaultInterestRateStrategy
   function getVariableRateSlope1() external view returns (uint256) {
     return _variableRateSlope1;
   }

-  /**
-   * @notice Returns the variable rate slope above optimal usage ratio
-   * @dev Its the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
-   * @return The variable rate slope
-   **/
+  /// @inheritdoc IDefaultInterestRateStrategy
   function getVariableRateSlope2() external view returns (uint256) {
     return _variableRateSlope2;
   }

-  /**
-   * @notice Returns the stable rate slope below optimal usage ratio
-   * @dev Its the stable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
-   * @return The stable rate slope
-   **/
+  /// @inheritdoc IDefaultInterestRateStrategy
   function getStableRateSlope1() external view returns (uint256) {
     return _stableRateSlope1;
   }

-  /**
-   * @notice Returns the stable rate slope above optimal usage ratio
-   * @dev Its the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
-   * @return The stable rate slope
-   **/
+  /// @inheritdoc IDefaultInterestRateStrategy
   function getStableRateSlope2() external view returns (uint256) {
     return _stableRateSlope2;
   }

-  /**
-   * @notice Returns the stable rate excess offset
-   * @dev An additional premium applied to the stable when stable debt > OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO
-   * @return The stable rate excess offset
-   */
+  /// @inheritdoc IDefaultInterestRateStrategy
   function getStableRateExcessOffset() external view returns (uint256) {
     return _stableRateExcessOffset;
   }

-  /**
-   * @notice Returns the base stable borrow rate
-   * @return The base stable borrow rate
-   **/
+  /// @inheritdoc IDefaultInterestRateStrategy
   function getBaseStableBorrowRate() public view returns (uint256) {
     return _variableRateSlope1 + _baseStableRateOffset;
   }

-  /// @inheritdoc IReserveInterestRateStrategy
+  /// @inheritdoc IDefaultInterestRateStrategy
   function getBaseVariableBorrowRate() external view override returns (uint256) {
     return _baseVariableBorrowRate;
   }

-  /// @inheritdoc IReserveInterestRateStrategy
+  /// @inheritdoc IDefaultInterestRateStrategy
   function getMaxVariableBorrowRate() external view override returns (uint256) {
     return _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
   }
@@ -1068,8 +1111,8 @@ contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
   }

   /// @inheritdoc IReserveInterestRateStrategy
-  function calculateInterestRates(DataTypes.CalculateInterestRatesParams calldata params)
-    external
+  function calculateInterestRates(DataTypes.CalculateInterestRatesParams memory params)
+    public
     view
     override
     returns (
@@ -1152,7 +1195,7 @@ contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
    * @param currentVariableBorrowRate The current variable borrow rate of the reserve
    * @param currentAverageStableBorrowRate The current weighted average of all the stable rate loans
    * @return The weighted averaged borrow rate
-   **/
+   */
   function _getOverallBorrowRate(
     uint256 totalStableDebt,
     uint256 totalVariableDebt,
```
