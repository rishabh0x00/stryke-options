// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/access/AccessControl.sol";
import "@uniswap-core/interfaces/IUniswapV3Pool.sol";

contract OptionToken is ERC20, AccessControl {
    bytes32 public constant OPTION_ADMIN = keccak256("OPTION_ADMIN");
        
    struct OptionTerms {
        uint256 strikePrice;
        uint256 expiry;
        bool isCall;
        address poolAddress;
        address creator;
        uint256 asset1Reserve;
        uint256 asset2Reserve;
    }

    OptionTerms public terms;
    IUniswapV3Pool public uniswapPool;

    // Private storage for the token name and symbol.
    string private _customName;
    string private _customSymbol;

    // Flag to ensure initialize() is only called once.
    bool private _initialized;

    modifier notInitialized() {
    require(!_initialized, "Already initialized");
    _initialized = true;
    _;
    }

    constructor() ERC20("", "") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _initialized = true; // Setting initialized to true here so that Implementation contract cannot be initialized later
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isCall,
        address _creator,
        address _poolAddress,
        uint256 _asset1Amt,
        uint256 _asset2Amt,
        address _admin
    ) external onlyRole(DEFAULT_ADMIN_ROLE) notInitialized {
        terms = OptionTerms(
            _strikePrice,
            _expiry,
            _isCall,
            _poolAddress,
            _creator,
            _asset1Amt,
            _asset2Amt
        );
        uniswapPool = IUniswapV3Pool(_poolAddress);
        _customName = _name;
        _customSymbol = _symbol;

        _grantRole(OPTION_ADMIN, _admin);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(_creator, _asset1Amt);
    }

    function calculateProfit(address user, uint256 amount) external view returns (bool, uint256) {
        require(balanceOf(user) >= amount, "Insufficient options");
        uint256 price = getAssetPrice();
        
        if (terms.isCall == true && price > terms.strikePrice) {
            return (true, (price - terms.strikePrice) * amount / 1e18);
        } 
        if (terms.isCall == false && price < terms.strikePrice) {
            return (true, (terms.strikePrice - price) * amount / 1e18);
        }
        return (false, 0);
    }

    function getAssetPrice() public view returns (uint256) {
        (uint160 sqrtPriceX96,,,,,,) = uniswapPool.slot0();
        uint256 priceX96 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        return priceX96 * 1e18 / (2**192); // Normalized to 18 decimals
    }

    function adminTransfer(address from, address to, uint256 amount) external onlyRole(OPTION_ADMIN) {
        _transfer(from, to, amount);
    }

    function burn(address account, uint256 amount) external onlyRole(OPTION_ADMIN) {
        _burn(account, amount);
    }


    /// @notice Override ERC20 name() to return our updated token name.
    function name() public view override returns (string memory) {
        return _customName;
    }

    /// @notice Override ERC20 symbol() to return our updated token symbol.
    function symbol() public view override returns (string memory) {
        return _customSymbol;
    }
}