# Options Protocol: European Options on Uniswap V3 LP Positions

This project implements a decentralized European-style options protocol on the Ethereum blockchain, leveraging Uniswap V3 liquidity positions as collateral. It allows users who hold Uniswap V3 LP NFTs to mint option tokens representing call or put options on the underlying asset pair of the liquidity pool.

## 📖 Overview

The Options Protocol consists of two main smart contracts:

*   **`OptionsVault.sol`**: This is the main contract that manages the entire option lifecycle. It handles:
    *   Minting of `OptionToken` contracts based on deposited Uniswap V3 LP NFTs.
    *   Facilitating the buying and selling of option tokens.
    *   Exercising options based on market conditions and expiry.
    *   Claiming of underlying assets by the option minter after expiry if options are not exercised.
*   **`OptionToken.sol`**: This contract represents the ERC20 option token itself. It is deployed as a minimal proxy clone for each minted option, keeping gas costs low. Each `OptionToken` contract represents a specific option with predefined terms like strike price, expiry, and option type (Call/Put).

**🚀 Core Functionality:**

1.  **Minting Options (for LP NFT Holders - Minters):**
    *   A user holding a Uniswap V3 LP NFT (Minter) for a supported pool (e.g., WETH/USDC) can use their NFT to mint option tokens.
    *   The Minter transfers their Uniswap V3 NFT token ID to the `OptionsVault` contract.
    *   The `OptionsVault` contract withdraws liquidity from the Uniswap V3 pool associated with the NFT.
    *   Based on the amount of `asset1` (e.g., WETH) withdrawn, a new `OptionToken` contract (a clone) is deployed using the `OptionToken.sol` implementation.
    *   Option tokens (ERC20) are minted to the Minter's address, representing the option on `asset1`.

2.  **Buying Options (for Option Buyers):**
    *   Any user can buy existing, unexpired option tokens from the original Minter.
    *   The buyer calls the `buyOption` function on the `OptionsVault`, specifying the `OptionToken` contract address and the amount of options they want to purchase.
    *   The buyer transfers the calculated premium (in `asset2`, e.g., USDC) to the Minter.
    *   The specified amount of `OptionToken` is transferred from the Minter to the buyer via an `adminTransfer` function, ensuring only valid transfers are made.

3.  **Exercising Options (for Option Holders):**
    *   Option holders can exercise their options during a predefined exercise window, starting 1 hour before the option expiry and ending at the expiry timestamp.
    *   To exercise, the holder calls the `exerciseOption` function on the `OptionsVault` with the `OptionToken` contract address and the amount of options to exercise.
    *   **Call Option Exercise Condition:** If it's a Call option, and the market price of `asset1` (from Uniswap V3 pool) is greater than the Strike Price, the option is "in-the-money" and profitable.
    *   **Put Option Exercise Condition:** If it's a Put option, and the market price of `asset1` is less than the Strike Price, the option is "in-the-money" and profitable.
    *   If profitable, the `OptionsVault` calculates the profit and transfers the profit amount (in `asset1` for Call, `asset2` for Put) to the option holder. The exercised option tokens are then burned.

4.  **Claiming Underlying Assets (for Minters after Expiry):**
    *   If options are not exercised by expiry, or if there are remaining option tokens held by the Minter after exercise, the Minter can claim back the underlying assets from the `OptionsVault`.
    *   The Minter calls the `claimTokens` function on the `OptionsVault`, specifying the `OptionToken` contract address.
    *   The `OptionsVault` transfers any remaining `asset1` and `asset2` amounts associated with the `OptionToken` back to the original Minter.

## Smart Contracts

### `OptionsVault.sol`

This contract serves as the central hub for option management.

**Key Functions:**

*   **`constructor(address _uniswapNFTManager, address _uniswapV3Factory, address _optionImplementation)`**:
    *   Initializes the contract with addresses of the Uniswap V3 Nonfungible Position Manager, Uniswap V3 Factory, and the `OptionToken` implementation contract.

    ```solidity
    constructor(
        address _uniswapNFTManager,
        address _uniswapV3Factory,
        address _optionImplementation
    ) {
        // ... constructor logic ...
    }
    ```

*   **`mintOption(uint256 tokenId, uint256 strikePrice, uint256 premium, uint256 expiry, bool isCall)`**:
    *   Allows a user to mint a new OptionToken by providing their Uniswap V3 LP NFT `tokenId`.
    *   Parameters include `strikePrice`, `premium` (per option token), `expiry` timestamp, and `isCall` (true for Call, false for Put).

    ```solidity
    function mintOption(
        uint256 tokenId,
        uint256 strikePrice,
        uint256 premium,
        uint256 expiry,
        bool isCall
    ) external nonReentrant {
        // ... mint option logic ...
    }
    ```

*   **`buyOption(address optionAddress, uint256 amount)`**:
    *   Allows any user to buy existing `OptionToken`s.
    *   Requires the `optionAddress` and `amount` of options to purchase.
    *   Calculates premium using `calculatePremium` and transfers premium from buyer to minter.

    ```solidity
    function buyOption(
        address optionAddress,
        uint256 amount
    ) external nonReentrant {
        // ... buy option logic ...
    }
    ```

*   **`exerciseOption(address optionAddress, uint256 amount)`**:
    *   Allows option holders to exercise their options if they are in-the-money during the exercise window.
    *   Requires the `optionAddress` and `amount` of options to exercise.
    *   Calls `calculateProfit` on the `OptionToken` to determine profitability and profit.
    *   Transfers profit to the exerciser and burns the exercised option tokens.

    ```solidity
    function exerciseOption(
        address optionAddress,
        uint256 amount
    ) external nonReentrant {
        // ... exercise option logic ...
    }
    ```

*   **`claimTokens(address optionAddress)`**:
    *   Allows the original option minter to claim back any remaining underlying assets (`asset1` and `asset2`) from the vault after the option expiry.
    *   Can only be called by the minter and after the option has expired.

    ```solidity
    function claimTokens(address optionAddress) external nonReentrant {
        // ... claim tokens logic ...
    }
    ```

*   **`calculatePremium(address optionAddress, uint256 amount) public view returns (uint256)`**:
    *   Calculates the premium cost for buying a specific `amount` of options for a given `optionAddress`.
    *   Retrieves the premium per option from the `OptionToken` contract and calculates the total premium.

    ```solidity
    function calculatePremium(
        address optionAddress,
        uint256 amount
    ) public view returns (uint256) {
        // ... calculate premium logic ...
    }
    ```

*   **`_mintOption(bytes memory optionData)`**:
    *   *(Internal Function)* Core logic for minting a new OptionToken.
    *   Withdraws liquidity from the Uniswap V3 LP position using `_withdrawAssets`.
    *   Generates option metadata (name, symbol) using `_generateOptionMetadata`.
    *   Deploys a clone of the `OptionToken` implementation using `Clones.clone`.
    *   Initializes the cloned `OptionToken` contract.
    *   Stores `OptionData` in the `optionByAddress` mapping.

    ```solidity
    function _mintOption(bytes memory optionData) internal {
        // ... mint option logic ...
    }
    ```

*   **`_transferAssets(address optionAddress, uint256 profit, bool isCall)`**:
    *   *(Internal Function)* Transfers profit to the option exerciser in either `asset1` (for Call options) or `asset2` (for Put options).
    *   Updates the remaining `asset1Amount` or `asset2Amount` in the `optionByAddress` mapping.

    ```solidity
    function _transferAssets(
        address optionAddress,
        uint256 profit,
        bool isCall
    ) internal {
        // ... transfer assets logic ...
    }
    ```

*   **`_getPoolAddress(uint256 tokenId) internal view returns (address)`**:
    *   *(Internal Function)* Retrieves the Uniswap V3 pool address associated with a given Uniswap V3 NFT `tokenId` by querying the `uniswapNFTManager`.

    ```solidity
    function _getPoolAddress(uint256 tokenId) internal view returns (address) {
        // ... get pool address logic ...
    }
    ```

*   **`_withdrawAssets(uint256 tokenId) internal returns (uint256 asset1Amt, uint256 asset2Amt, address asset1)`**:
    *   *(Internal Function)* Withdraws liquidity (both tokens and fees) from a Uniswap V3 LP position represented by `tokenId`.
    *   Uses `uniswapNFTManager.decreaseLiquidity` to remove all liquidity from the position.
    *   Uses `uniswapNFTManager.collect` to collect accumulated fees.
    *   Returns the amounts of `asset1` and `asset2` withdrawn, and the address of `asset1`.

    ```solidity
    function _withdrawAssets(
        uint256 tokenId
    ) internal returns (uint256 asset1Amt, uint256 asset2Amt, address asset1) {
        // ... withdraw assets logic ...
    }
    ```

*   **`_formatStrikePrice(uint256 price, uint8 decimals) internal pure returns (string memory)` & `_uintToString(uint256 value) internal pure returns (string memory)`**:
    *   *(Internal Utility Functions)* Helper functions for formatting the strike price as a string for use in option metadata.

    ```solidity
    function _formatStrikePrice(
        uint256 price,
        uint8 decimals
    ) internal pure returns (string memory) {
        // ... format strike price logic ...
    }

    function _uintToString(
        uint256 value
    ) internal pure returns (string memory) {
        // ... uint to string conversion logic ...
    }
    ```

*   **`_generateOptionMetadata(address asset1, uint256 strikePrice, bool isCall) internal view returns (string memory optionName, string memory optionSymbol)`**:
    *   *(Internal Function)* Generates a human-readable name and symbol for the `OptionToken` based on the underlying `asset1`, `strikePrice`, and option `isCall` type.

    ```solidity
    function _generateOptionMetadata(
        address asset1,
        uint256 strikePrice,
        bool isCall
    )
        internal
        view
        returns (string memory optionName, string memory optionSymbol)
    {
        // ... generate option metadata logic ...
    }
    ```

### `OptionToken.sol`

This contract is the ERC20 token representing a specific option. It is deployed as a minimal proxy clone to save gas.

**Key Features:**

*   **ERC20 Compliance:** Implements the ERC20 token standard, allowing for standard token interactions (transfer, balance checks, etc.).
*   **Access Control:** Uses OpenZeppelin's `AccessControl` for managing administrative functions. The `OPTION_ADMIN` role is granted to the `OptionsVault` contract, allowing it to perform administrative actions like `adminTransfer` and `burn`.
*   **Reentrancy Guard:**  Uses OpenZeppelin's `ReentrancyGuard` to protect against reentrancy attacks.
*   **Minimal Proxy Clone:** Deployed as a clone using `Clones.clone` to minimize deployment gas costs.
*   **Option Terms Storage:**  Stores the terms of the option (strike price, premium, expiry, call/put type, associated Uniswap pool, etc.) in the `terms` struct.
*   **Price Oracle:** Uses the associated Uniswap V3 pool as a price oracle to determine the market price of the underlying asset (`asset1`).

**Key Functions:**

*   **`initialize(bytes calldata optionData, string memory _name, string memory _symbol, address _poolAddress, uint256 _asset1Amt, uint256 _asset2Amt, address _admin)`**:
    *   Initializes the cloned `OptionToken` contract. This function is called by the `OptionsVault` during the minting process and can only be called once.
    *   Sets the option terms, token name, symbol, and grants `OPTION_ADMIN` and `DEFAULT_ADMIN_ROLE` to the `OptionsVault` contract.
    *   Mints initial option tokens to the option minter based on the `asset1Amt`.

    ```solidity
    function initialize(
        bytes calldata optionData,
        string memory _name,
        string memory _symbol,
        address _poolAddress,
        uint256 _asset1Amt,
        uint256 _asset2Amt,
        address _admin
    ) external notInitialized nonReentrant {
        // ... initialize option token logic ...
    }
    ```

*   **`adminTransfer(address from, address to, uint256 amount)`**:
    *   Allows the `OPTION_ADMIN` (i.e., `OptionsVault`) to transfer option tokens between addresses. This is used in the `buyOption` function of `OptionsVault`.

    ```solidity
    function adminTransfer(
        address from,
        address to,
        uint256 amount
    ) external onlyRole(OPTION_ADMIN) nonReentrant {
        // ... admin transfer logic ...
    }
    ```

*   **`burn(address account, uint256 amount)`**:
    *   Allows the `OPTION_ADMIN` (i.e., `OptionsVault`) to burn option tokens. Used when options are exercised or when remaining options are burned after expiry (though not currently implemented for minter claim).

    ```solidity
    function burn(
        address account,
        uint256 amount
    ) external onlyRole(OPTION_ADMIN) nonReentrant {
        // ... burn logic ...
    }
    ```

*   **`calculateProfit(address user, uint256 amount) external view returns (bool profitable, uint256 profit)`**:
    *   Calculates the profit for a given amount of option tokens held by a user.
    *   Determines if the option is "in-the-money" based on the current market price of `asset1` from the Uniswap V3 pool and the option's strike price and type (Call/Put).
    *   Returns `profitable` (boolean) and the `profit` amount if the option is in-the-money, otherwise `profitable` is false and `profit` is 0.

    ```solidity
    function calculateProfit(
        address user,
        uint256 amount
    ) external view returns (bool profitable, uint256 profit) {
        // ... calculate profit logic ...
    }
    ```

*   **`getAsset1Price() public view returns (uint256)`**:
    *   Fetches the current price of `asset1` (the underlying asset) from the associated Uniswap V3 pool using `uniswapPool.slot0()`.
    *   Calculates the price based on the sqrtPriceX96 value and the decimals of `asset1` and `asset2`.

    ```solidity
    function getAsset1Price() public view returns (uint256) {
        // ... get asset1 price logic ...
    }
    ```

*   **`convertAsset2ToAsset1(uint256 amount) public view returns (uint256)`**:
    *   Converts a given `amount` of `asset2` to its equivalent value in `asset1` based on the current market price from the Uniswap V3 pool.

    ```solidity
    function convertAsset2ToAsset1(
        uint256 amount
    ) public view returns (uint256) {
        // ... convert asset2 to asset1 logic ...
    }
    ```

*   **`getAsset1Address() public view returns (address)` & `getAsset2Address() public view returns (address)`**:
    *   Helper functions to retrieve the addresses of `asset1` (token0) and `asset2` (token1) from the associated Uniswap V3 pool.

    ```solidity
    function getAsset1Address() public view returns (address) {
        // ... get asset1 address logic ...
    }

    function getAsset2Address() public view returns (address) {
        // ... get asset2 address logic ...
    }
    ```

*   **`name() public view override returns (string memory)` & `symbol() public view override returns (string memory)`**:
    *   Overrides ERC20 `name()` and `symbol()` functions to return the custom option name and symbol set during initialization.

    ```solidity
    function name() public view override returns (string memory) {
        // ... return custom name ...
    }

    function symbol() public view override returns (string memory) {
        // ... return custom symbol ...
    }
    ```

## Assumptions

*   **Sufficient Liquidity Coverage:** When an LP position (e.g., WETH/USDC) is withdrawn via `_withdrawAssets`, the total collected amounts (`asset1Amount` + `asset2Amount`) are considered sufficient to cover all potential option payouts. This assumes that the value extracted from the LP position is adequate to collateralize the options being minted.
*   **Uniswap V3 Pool as Price Oracle:** The protocol relies on the Uniswap V3 pool's spot price as a reliable source for determining the market price of `asset1` for option exercising and profit calculation.
*   **European Style Options:** The options implemented are European style, meaning they can only be exercised at expiry, or within the exercise window just before expiry.
*   **Simplified Profit Transfer:** The profit transfer mechanism (in `_transferAssets`) is simplified for demonstration purposes. A production implementation would likely involve a more robust vault or settlement mechanism to handle asset transfers and potentially custody of the underlying assets.

## Design Choices

*   **Unbounded Strike Price and Expiry:** The protocol allows for flexibility in setting strike prices to any value greater than zero and does not impose specific limitations on option expiry times (e.g., daily, weekly, monthly). This design choice prioritizes flexibility over standardization and allows for a wider range of option types to be created. While traditional finance options often have structured strike price and expiry ranges, this decentralized protocol opts for greater user-defined customization.
*   **Minimal Proxy Clones for Option Tokens:** `OptionToken` contracts are deployed as minimal proxy clones to significantly reduce gas costs associated with deploying a separate contract for each option minted. This makes the protocol more gas-efficient and scalable.
*   **Decentralized Price Oracle:** Leveraging the Uniswap V3 pool directly as a price oracle provides a decentralized and readily available price feed for option valuation and exercise conditions, reducing reliance on external centralized oracles.

## Security Considerations

*   **Reentrancy Protection:** The `OptionsVault` and `OptionToken` contracts implement OpenZeppelin's `ReentrancyGuard` to mitigate reentrancy attack risks.
*   **Access Control:**  `AccessControl` from OpenZeppelin is used in `OptionToken` to manage administrative functions, ensuring only authorized contracts (like `OptionsVault`) can perform administrative actions.
*   **SafeERC20 Usage:**  `SafeERC20` is used for ERC20 token transfers to prevent issues with tokens that don't strictly adhere to the ERC20 standard, enhancing robustness.
