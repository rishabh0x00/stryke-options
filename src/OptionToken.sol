// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/access/AccessControl.sol";
import "@uniswap-core/interfaces/IUniswapV3Pool.sol";

contract OptionToken is ERC20, AccessControl {
    bytes32 public constant OPTION_ADMIN = keccak256("OPTION_ADMIN");

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

    /// @notice Override ERC20 name() to return our updated token name.
    function name() public view override returns (string memory) {
        return _customName;
    }

    /// @notice Override ERC20 symbol() to return our updated token symbol.
    function symbol() public view override returns (string memory) {
        return _customSymbol;
    }
}