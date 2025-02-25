// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/token/ERC721/IERC721Receiver.sol";
import "@uniswap/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/interfaces/INonfungiblePositionManager.sol";
import "@openzeppelin/proxy/Clones.sol";
import "./OptionToken.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

contract OptionsVault is IERC721Receiver {
    using Clones for address;

    INonfungiblePositionManager public uniswapNFTManager;
    address public optionImplementation;

    struct OptionData {
        address creator;
        address optionContract;
        uint256 asset1Amount;
        uint256 asset2Amount;
    }

    mapping(uint256 => OptionData) public options; // LP Token ID → Option
    mapping(address => OptionData) public optionByAddress;

    constructor(address _uniswapNFTManager, address _optionImplementation) {
        uniswapNFTManager = INonfungiblePositionManager(_uniswapNFTManager);
        optionImplementation = _optionImplementation;
    }

    // Create option through ERC721 transfer
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        (uint256 strikePrice, uint256 expiry, bool isCall) = abi.decode(
            data,
            (uint256, uint256, bool)
        );
        _createOption(from, tokenId, strikePrice, expiry, isCall);
        return this.onERC721Received.selector;
    }

    // Manual option creation with NFT transfer
    function createOption(
        uint256 tokenId,
        uint256 strikePrice,
        uint256 expiry,
        bool isCall
    ) external {
        uniswapNFTManager.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            ""
        );
        _createOption(msg.sender, tokenId, strikePrice, expiry, isCall);
    }

    // Core option creation logic
    function _createOption(
        address creator,
        uint256 tokenId,
        uint256 strikePrice,
        uint256 expiry,
        bool isCall
    ) internal {
        (uint256 asset1Amt, uint256 asset2Amt, address asset1) = _withdrawAssets(tokenId);

        address option = Clones.clone(optionImplementation);
        OptionERC20(option).initialize(
            "Option", // TODO 
            "OP",
            strikePrice,
            expiry,
            isCall,
            creator,
            _getPoolAddress(tokenId),
            asset1Amt,
            asset2Amt,
            address(this)
        );

        OptionData memory data = OptionData(
            creator,
            option,
            asset1Amt,
            asset2Amt
        );
        options[tokenId] = data;
        optionByAddress[option] = data;
    }

    // Helper to get pool address from NFT
    function _getPoolAddress(uint256 tokenId) internal view returns (address) {
        (, , address token0, address token1, , , , , , , , ) = uniswapNFTManager
            .positions(tokenId);
        return
            address(
                uint160(uint256(keccak256(abi.encodePacked(token0, token1))))
            );
    }
}
