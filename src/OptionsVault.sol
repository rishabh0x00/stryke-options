// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "openzeppelin/token/ERC721/IERC721Receiver.sol";
import "openzeppelin/token/ERC721/IERC721.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/IUniswapV3Factory.sol";
import "openzeppelin/proxy/Clones.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/utils/ReentrancyGuard.sol";
import "./OptionToken.sol";

/**
 * @title OptionsVault
 * @notice This contract manages the creation, purchase, exercise, and token claims of option tokens
 *         derived from Uniswap V3 LP positions.
 */
contract OptionsVault is IERC721Receiver, ReentrancyGuard {
    using Clones for address;
    using SafeERC20 for IERC20;

    INonfungiblePositionManager public uniswapNFTManager;
    IUniswapV3Factory public uniswapV3Factory;
    address public optionImplementation;

    /// @notice Emitted when an option is created.
    event OptionCreated(
        address indexed optionAddress,
        uint256 indexed tokenId,
        address indexed creator,
        uint256 asset1Amount,
        uint256 asset2Amount
    );
    
    /// @notice Emitted when an option is bought.
    event OptionBought(
        address indexed buyer,
        address indexed optionAddress,
        uint256 amount,
        uint256 premium
    );
    
    /// @notice Emitted when an option is exercised.
    event OptionExercised(
        address indexed exerciser,
        address indexed optionAddress,
        uint256 amount,
        uint256 profit
    );
    
    /// @notice Emitted when the option creator claims remaining tokens.
    event OptionClaimed(
        address indexed creator,
        address indexed optionAddress
    );

    /**
     * @notice OptionData holds details about an option created from an LP token.
     * @param creator The address that created the option.
     * @param tokenId The NFT token ID that was used to create the option.
     * @param asset1Amount The amount of asset1 withdrawn from the LP.
     * @param asset2Amount The amount of asset2 withdrawn from the LP.
     */
    struct OptionData {
        address creator;
        uint256 tokenId;
        uint256 asset1Amount;
        uint256 asset2Amount;
    }

    /// @notice Mapping from option contract address to its OptionData.
    mapping(address => OptionData) public optionByAddress;

    /**
     * @notice Constructor for OptionsVault.
     * @param _uniswapNFTManager Address of the Uniswap Nonfungible Position Manager.
     * @param _uniswapV3Factory Address of the Uniswap V3 Factory.
     * @param _optionImplementation Address of the deployed OptionToken implementation.
     */
    constructor(
        address _uniswapNFTManager,
        address _uniswapV3Factory,
        address _optionImplementation
    ) {
        require(_uniswapNFTManager != address(0), "Zero NFT Manager address");
        require(_uniswapV3Factory != address(0), "Zero V3 Factory address");
        require(_optionImplementation != address(0), "Zero Option implementation address");

        uniswapNFTManager = INonfungiblePositionManager(_uniswapNFTManager);
        uniswapV3Factory = IUniswapV3Factory(_uniswapV3Factory);
        optionImplementation = _optionImplementation;
    }

    /**
     * @notice Called upon receipt of an ERC721 token. Decodes option parameters from `data`
     *         and creates an option.
     * @param from The address which previously owned the token.
     * @param tokenId The NFT token ID being transferred.
     * @param data Encoded option parameters (strikePrice, premium, expiry, isCall).
     * @return The selector to confirm token receipt.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override nonReentrant returns (bytes4) {
        require(from != address(0), "Invalid sender address");
        require(tokenId != 0, "Invalid token ID");

        (uint256 strikePrice, uint256 premium, uint256 expiry, bool isCall) = abi.decode(
            data,
            (uint256, uint256, uint256, bool)
        );
        // Encode additional option data including creator and tokenId.
        bytes memory optionData = abi.encode(strikePrice, premium, expiry, isCall, from, tokenId);
        _createOption(optionData);
        return this.onERC721Received.selector;
    }

    /**
     * @notice Allows manual creation of an option by transferring the NFT to the vault.
     * @param tokenId The NFT token ID.
     * @param strikePrice Strike price for the option.
     * @param premium Premium for the option.
     * @param expiry Expiry timestamp for the option.
     * @param isCall True if Call option, false if Put.
     */
    function createOption(
        uint256 tokenId,
        uint256 strikePrice,
        uint256 premium,
        uint256 expiry,
        bool isCall
    ) external nonReentrant {
        require(tokenId != 0, "Invalid token ID");
        require(strikePrice > 0, "Strike price must be > 0");
        require(expiry > block.timestamp, "Expiry must be in the future");

        IERC721(address(uniswapNFTManager)).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            ""
        );
        bytes memory optionData = abi.encode(strikePrice, premium, expiry, isCall, msg.sender, tokenId);
        _createOption(optionData);
    }

    /**
     * @notice Allows a user to buy options from the option creator.
     * @param optionAddress Address of the option contract.
     * @param amount Amount of options to buy.
     */
    function buyOption(
        address optionAddress,
        uint256 amount
    ) external nonReentrant {
        require(optionAddress != address(0), "Invalid option address");
        require(amount > 0, "Zero option amount");

        OptionData memory data = optionByAddress[optionAddress];
        require(data.creator != address(0), "Invalid option");

        OptionToken option = OptionToken(optionAddress);
        (, , uint256 expiry, , , , , ) = option.terms();
        // Ensure that the option is not already in the exercise window or expired.
        require(block.timestamp < expiry - 1 hours, "Option in exercise window or expired");
        require(option.balanceOf(data.creator) >= amount, "Insufficient creator balance");

        uint256 premium = calculatePremium(optionAddress, amount);
        IERC20(option.getAsset2Address()).safeTransferFrom(msg.sender, data.creator, premium);
        option.adminTransfer(data.creator, msg.sender, amount);

        emit OptionBought(msg.sender, optionAddress, amount, premium);
    }

    /**
     * @notice Allows an option holder to exercise their option.
     * @param optionAddress Address of the option contract.
     * @param amount Amount of options to exercise.
     */
    function exerciseOption(
        address optionAddress,
        uint256 amount
    ) external nonReentrant {
        require(optionAddress != address(0), "Invalid option address");
        require(amount > 0, "Zero amount");

        OptionToken option = OptionToken(optionAddress);
        (, , uint256 expiry, bool isCall, , , , ) = option.terms();
        // Ensure that the exercise window is open.
        require(
            block.timestamp >= expiry - 1 hours && block.timestamp <= expiry,
            "Exercise window closed"
        );

        (bool profitable, uint256 profit) = option.calculateProfit(msg.sender, amount);
        require(profitable, "Option not profitable");
        
        _transferAssets(optionAddress, profit, isCall);
        option.burn(msg.sender, amount);

        emit OptionExercised(msg.sender, optionAddress, amount, profit);
    }

    /**
     * @notice Allows the option creator to claim remaining tokens after option expiry.
     * @param optionAddress Address of the option contract.
     */
    function claimTokens(address optionAddress) external nonReentrant {
        require(optionAddress != address(0), "Invalid option address");

        OptionData storage data = optionByAddress[optionAddress];
        require(data.creator == msg.sender, "Caller is not option creator");

        OptionToken option = OptionToken(optionAddress);
        (, , uint256 expiry, , , , , ) = option.terms();
        require(block.timestamp > expiry, "Option has not expired");

        IERC20(option.getAsset1Address()).safeTransfer(data.creator, data.asset1Amount);
        IERC20(option.getAsset2Address()).safeTransfer(data.creator, data.asset2Amount);

        emit OptionClaimed(data.creator, optionAddress);
    }

    /**
     * @notice Calculates the premium for a given amount of options.
     * @param optionAddress Address of the option contract.
     * @param amount Amount of options.
     * @return The premium to be paid.
     */
    function calculatePremium(
        address optionAddress,
        uint256 amount
    ) public view returns (uint256) {
        require(optionAddress != address(0), "Invalid option address");
        OptionToken option = OptionToken(optionAddress);
        (, uint256 premium, , , , , , ) = option.terms();
        return (amount * premium) / (10 ** option.decimals());
    }

    /**
     * @notice Internal function that contains the core logic for creating an option.
     * @dev Decodes the abi-encoded option data, withdraws assets from the LP, generates option metadata,
     *      and deploys a clone of the OptionToken contract.
     * @param optionData The ABI-encoded data containing values for the Option contract.
     */
    function _createOption(bytes memory optionData) internal {
        // Decode required values and check validity.
        (
            uint256 strikePrice,
            ,
            uint256 expiry,
            bool isCall,
            address creator,
            uint256 tokenId
        ) = abi.decode(optionData, (uint256, uint256, uint256, bool, address, uint256));
        require(creator != address(0), "Zero creator address");
        require(strikePrice > 0, "Zero strike price");
        require(expiry > block.timestamp + 1 hours, "Invalid expiry");

        // Withdraw assets from the LP position.
        (uint256 asset1Amt, uint256 asset2Amt, address asset1) = _withdrawAssets(tokenId);
        require(asset1Amt > 0 && asset2Amt > 0, "Zero asset amounts");

        // Generate option metadata (name & symbol)
        (string memory optionName, string memory optionSymbol) = _generateOptionMetadata(asset1, strikePrice, isCall);
        // Create clone of OptionToken implementation.
        address option = Clones.clone(optionImplementation);
        // Here we assume initialize signature for OptionToken clone accepts:
        // (bytes initData, string memory optionName, string memory optionSymbol, address poolAddress, uint256 asset1Amt, uint256 asset2Amt, address admin)
        OptionToken(option).initialize(
            optionData,
            optionName,
            optionSymbol,
            _getPoolAddress(tokenId),
            asset1Amt,
            asset2Amt,
            address(this)
        );

        OptionData memory newData = OptionData(
            creator,
            tokenId,
            asset1Amt,
            asset2Amt
        );
        optionByAddress[option] = newData;

        emit OptionCreated(option, tokenId, creator, asset1Amt, asset2Amt);
    }

    /**
     * @notice Transfers assets to the caller based on the option profit.
     * @param optionAddress Address of the option contract.
     * @param profit Profit amount calculated.
     * @param isCall True if Call option, false if Put.
     */
    function _transferAssets(
        address optionAddress,
        uint256 profit,
        bool isCall
    ) internal {
        require(optionAddress != address(0), "Invalid option address");
        OptionData storage data = optionByAddress[optionAddress];
        OptionToken option = OptionToken(optionAddress);
        if (isCall) {
            uint256 profitInAsset1 = option.convertAsset2ToAsset1(profit);
            IERC20(option.getAsset1Address()).safeTransfer(msg.sender, profitInAsset1);
            data.asset1Amount -= profitInAsset1;
        } else {
            IERC20(option.getAsset2Address()).safeTransfer(msg.sender, profit);
            data.asset2Amount -= profit;
        }
    }

    /**
     * @notice Retrieves the pool address for a given NFT token ID.
     * @param tokenId NFT token ID.
     * @return The corresponding Uniswap V3 pool address.
     */
    function _getPoolAddress(uint256 tokenId) internal view returns (address) {
        require(tokenId != 0, "Invalid token ID");
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = uniswapNFTManager.positions(tokenId);
        return uniswapV3Factory.getPool(token0, token1, fee);
    }

    /**
     * @notice Withdraws assets from a Uniswap V3 position.
     * @param tokenId NFT token ID representing the LP position.
     * @return asset1Amt Amount of asset1 withdrawn.
     * @return asset2Amt Amount of asset2 withdrawn.
     * @return asset1 Address of asset1.
     */
    function _withdrawAssets(
        uint256 tokenId
    ) internal returns (uint256 asset1Amt, uint256 asset2Amt, address asset1) {
        require(tokenId != 0, "Invalid token ID");
        (
            ,
            ,
            address token0,
            ,
            ,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,

        ) = uniswapNFTManager.positions(tokenId);

        // Decrease all liquidity
        INonfungiblePositionManager.DecreaseLiquidityParams memory decreaseParams = INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: liquidity,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });

        (uint256 amount0, uint256 amount1) = uniswapNFTManager.decreaseLiquidity(decreaseParams);

        // Collect fees
        INonfungiblePositionManager.CollectParams memory collectParams = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        (uint256 collected0, uint256 collected1) = uniswapNFTManager.collect(collectParams);

        asset1Amt = amount0 + collected0;
        asset2Amt = amount1 + collected1;
        asset1 = token0;
    }

    /**
     * @notice Formats the strike price for display.
     * @param price Strike price value.
     * @param decimals Number of decimals.
     * @return The formatted strike price as a string.
     */
    function _formatStrikePrice(
        uint256 price,
        uint8 decimals
    ) internal pure returns (string memory) {
        uint256 formattedPrice = price / (10 ** decimals);
        return _uintToString(formattedPrice);
    }

    /**
     * @notice Converts a uint256 value to its ASCII string representation.
     * @param value The uint256 value.
     * @return The string representation of the value.
     */
    function _uintToString(
        uint256 value
    ) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @notice Generates option metadata (name and symbol) based on the underlying asset and strike price.
     * @param asset1 Address of asset1.
     * @param strikePrice Strike price.
     * @param isCall True if Call option, false if Put.
     * @return optionName Generated token name.
     * @return optionSymbol Generated token symbol.
     */
    function _generateOptionMetadata(
        address asset1,
        uint256 strikePrice,
        bool isCall
    )
        internal
        view
        returns (string memory optionName, string memory optionSymbol)
    {
        require(asset1 != address(0), "Invalid asset address");
        string memory assetSymbol = ERC20(asset1).symbol();
        uint8 decimals = ERC20(asset1).decimals();
        string memory strikePriceStr = _formatStrikePrice(strikePrice, decimals);

        // Generate name and symbol based on option type.
        string memory typeStr = isCall ? "Call" : "Put";
        string memory typeSymbol = isCall ? "C" : "P";

        optionName = string(abi.encodePacked(assetSymbol, " ", typeStr, " ", strikePriceStr));
        optionSymbol = string(abi.encodePacked(assetSymbol, "-", typeSymbol, "-", strikePriceStr));
    }
}
