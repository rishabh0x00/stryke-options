// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/access/AccessControl.sol";
import "openzeppelin/utils/ReentrancyGuard.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUniswapV3Pool.sol";

/// @title OptionToken
/// @notice ERC20 token representing an option derived from Uniswap V3 liquidity.
/// @dev Uses AccessControl for role management and ReentrancyGuard to prevent reentrant calls.
contract OptionToken is ERC20, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Role identifier for accounts that can perform admin transfers and burns.
    bytes32 public constant OPTION_ADMIN = keccak256("OPTION_ADMIN");

    /**
     * @notice Structure containing the option's terms.
     * @param strikePrice The strike price for the option.
     * @param premium The premium for the option.
     * @param expiry The expiry timestamp for the option.
     * @param isCall True if the option is a call, false if a put.
     * @param uniswapPool The Uniswap V3 pool used for the price feed.
     * @param creator The address that created the option.
     * @param asset1Reserve The reserve amount for asset1.
     * @param asset2Reserve The reserve amount for asset2.
     */
    struct OptionTerms {
        uint256 strikePrice;
        uint256 premium;
        uint256 expiry;
        bool isCall;
        IUniswapV3Pool uniswapPool;
        address creator;
        uint256 asset1Reserve;
        uint256 asset2Reserve;
    }

    /// @notice Stores the terms for this option.
    OptionTerms public terms;
    /// @notice Uniswap pool instance for price retrieval.
    IUniswapV3Pool public uniswapPool;

    // Private storage for the token name and symbol.
    string private _customName;
    string private _customSymbol;

    // Flag to ensure initialize() is only called once.
    bool private _initialized;

    /// @notice Emitted when the contract is initialized.
    event Initialized(
        uint256 strikePrice,
        uint256 premium,
        uint256 expiry,
        bool isCall,
        address creator
    );

    /// @notice Emitted when an admin transfer occurs.
    event AdminTransfer(address indexed from, address indexed to, uint256 amount);

    /// @notice Emitted when tokens are burned.
    event TokensBurned(address indexed account, uint256 amount);

    /**
     * @notice Modifier to ensure the contract is not already initialized.
     */
    modifier notInitialized() {
        require(!_initialized, "Already initialized");
        _initialized = true;
        _;
    }

    /**
     * @notice Constructor for the implementation contract.
     * @dev The constructor disables initialization on the implementation so that clones must be initialized.
     */
    constructor() ERC20("", "") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _initialized = true; // Prevent implementation contract from being initialized later.
    }

    /**
     * @notice Initializes a clone of the OptionToken.
     * @dev Can only be called once. The caller must have DEFAULT_ADMIN_ROLE.
     * @param optionData The abi encoded data containing initialization values for Option.
     */
    function initialize(bytes calldata optionData, string memory _name, string memory _symbol, address _poolAddress,uint256 _asset1Amt,uint256 _asset2Amt,address _admin) external onlyRole(DEFAULT_ADMIN_ROLE) notInitialized nonReentrant {
        (
        uint256 _strikePrice,
        uint256 _premium,
        uint256 _expiry,
        bool _isCall,
        address _creator,
        
    ) = abi.decode(optionData, (uint256, uint256, uint256, bool, address, uint256));
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_symbol).length > 0, "Symbol cannot be empty");
        require(_poolAddress != address(0), "Pool address is zero");

        terms = OptionTerms({
            strikePrice: _strikePrice,
            premium: _premium,
            expiry: _expiry,
            isCall: _isCall,
            uniswapPool: IUniswapV3Pool(_poolAddress),
            creator: _creator,
            asset1Reserve: _asset1Amt,
            asset2Reserve: _asset2Amt
        });
        uniswapPool = IUniswapV3Pool(_poolAddress);

        // Set custom token details.
        _customName = _name;
        _customSymbol = _symbol;

        // Grant roles.
        _grantRole(OPTION_ADMIN, _admin);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);

        uint256 asset1Decimals = ERC20(getAsset1Address()).decimals();
        uint256 optionAmount = _asset1Amt * (10 ** (18 - asset1Decimals));
        _mint(_creator, optionAmount);

        emit Initialized(_strikePrice, _premium, _expiry, _isCall, _creator);
    }

    /**
     * @notice Transfers tokens from one address to another.
     * @dev Only callable by accounts with the OPTION_ADMIN role.
     * @param from The address to transfer tokens from.
     * @param to The recipient address.
     * @param amount The amount of tokens to transfer.
     */
    function adminTransfer(
        address from,
        address to,
        uint256 amount
    ) external onlyRole(OPTION_ADMIN) nonReentrant {
        require(
            from != address(0) && to != address(0),
            "Zero address provided"
        );
        require(amount > 0, "Amount must be greater than zero");
        _transfer(from, to, amount);
        emit AdminTransfer(from, to, amount);
    }

    /**
     * @notice Burns a specified amount of tokens from an account.
     * @dev Only callable by accounts with the OPTION_ADMIN role.
     * @param account The address whose tokens will be burned.
     * @param amount The amount of tokens to burn.
     */
    function burn(
        address account,
        uint256 amount
    ) external onlyRole(OPTION_ADMIN) nonReentrant {
        require(account != address(0), "Zero address provided");
        require(amount > 0, "Amount must be greater than zero");
        _burn(account, amount);
        emit TokensBurned(account, amount);
    }

    /**
     * @notice Calculates the profit for a given option amount held by a user.
     * @param user The address of the user.
     * @param amount The amount of option tokens.
     * @return profitable True if the option is profitable.
     * @return profit The calculated profit amount.
     */
    function calculateProfit(
        address user,
        uint256 amount
    ) external view returns (bool profitable, uint256 profit) {
        require(balanceOf(user) >= amount, "Insufficient options");
        uint256 price = getAsset1Price();

        if (terms.isCall && price > terms.strikePrice) {
            profitable = true;
            profit =
                ((price - terms.strikePrice) * amount) /
                (10 ** decimals());
        } else if (!terms.isCall && price < terms.strikePrice) {
            profitable = true;
            profit =
                ((terms.strikePrice - price) * amount) /
                (10 ** decimals());
        } else {
            profitable = false;
            profit = 0;
        }
    }

    /**
     * @notice Retrieves the current price of asset1 from the Uniswap V3 pool.
     * @return The price of asset1 normalized to 18 decimals.
     */
    function getAsset1Price() public view returns (uint256) {
        (uint160 sqrtPriceX96, , , , , , ) = uniswapPool.slot0();
        uint256 priceX96 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        uint256 decimals0 = 10 ** ERC20(getAsset1Address()).decimals();
        uint256 decimals1 = 10 ** ERC20(getAsset2Address()).decimals();
        return (priceX96 * decimals0) / (decimals1 << 192);
    }

    /**
     * @notice Converts an amount of asset2 to asset1 using the current price.
     * @param amount The amount of asset2.
     * @return The equivalent amount of asset1.
     */
    function convertAsset2ToAsset1(
        uint256 amount
    ) public view returns (uint256) {
        return
            (amount * (10 ** ERC20(getAsset1Address()).decimals())) /
            getAsset1Price();
    }

    /**
     * @notice Returns the address of asset1 from the Uniswap pool.
     * @return The asset1 token address.
     */
    function getAsset1Address() public view returns (address) {
        return terms.uniswapPool.token0();
    }

    /**
     * @notice Returns the address of asset2 from the Uniswap pool.
     * @return The asset2 token address.
     */
    function getAsset2Address() public view returns (address) {
        return terms.uniswapPool.token0();
    }

    /**
     * @notice Overrides the ERC20 name() function to return the custom token name.
     * @return The custom token name.
     */
    function name() public view override returns (string memory) {
        return _customName;
    }

    /**
     * @notice Overrides the ERC20 symbol() function to return the custom token symbol.
     * @return The custom token symbol.
     */
    function symbol() public view override returns (string memory) {
        return _customSymbol;
    }
}
