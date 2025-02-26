import { optionVaultContract, optionTokenContract, provider } from '../utils/contractInstance.js';
import { handleBlockchainTransaction } from '../utils/helpers.js';

export const initializeOption = catchAsync(async (req, res) => {
    const { optionData, name, symbol, poolAddress, asset1Amt, asset2Amt, admin } = req.body;

    if (!optionData || !name || !symbol || !poolAddress || !admin) {
        return res.status(400).json({ error: "Missing required parameters" });
    }

    const tx = await optionTokenContract.initialize(
        optionData,
        name,
        symbol,
        poolAddress,
        asset1Amt,
        asset2Amt,
        admin
    );

    const receipt = await handleBlockchainTransaction(tx);

    res.status(200).json({
        message: "Option token initialized successfully",
        txHash: receipt.transactionHash,
    });
});

export const adminTransfer = catchAsync(async (req, res) => {
    const { from, to, amount } = req.body;

    if (!from || !to || !amount) {
        return res.status(400).json({ error: "Missing required parameters" });
    }

    const tx = await optionTokenContract.adminTransfer(from, to, amount);
    const receipt = await handleBlockchainTransaction(tx);

    res.status(200).json({
        message: "Tokens transferred successfully",
        txHash: receipt.transactionHash,
    });
});

export const burnOption = catchAsync(async (req, res) => {
    const { account, amount } = req.body;

    if (!account || !amount) {
        return res.status(400).json({ error: "Missing required parameters" });
    }

    const tx = await optionTokenContract.burn(account, amount);
    const receipt = await handleBlockchainTransaction(tx);

    res.status(200).json({
        message: "Tokens burned successfully",
        txHash: receipt.transactionHash,
    });
});

export const calculateProfit = catchAsync(async (req, res) => {
    const { user, amount } = req.body;

    if (!user || !amount) {
        return res.status(400).json({ error: "Missing required parameters" });
    }

    const [profitable, profit] = await optionTokenContract.calculateProfit(user, amount);

    res.status(200).json({
        profitable,
        profit: profit.toString(),
    });
});

export const getAsset1Price = catchAsync(async (req, res) => {
    const price = await optionTokenContract.getAsset1Price();
    res.status(200).json({ price: price.toString() });
});

export const convertAsset2ToAsset1 = catchAsync(async (req, res) => {
    const { amount } = req.body;

    if (!amount) {
        return res.status(400).json({ error: "Missing required parameters" });
    }

    const convertedAmount = await optionTokenContract.convertAsset2ToAsset1(amount);

    res.status(200).json({
        convertedAmount: convertedAmount.toString(),
    });
});

export const getOptionTerms = catchAsync(async (req, res) => {
    const terms = await optionTokenContract.terms();

    res.status(200).json({
        strikePrice: terms.strikePrice.toString(),
        premium: terms.premium.toString(),
        expiry: terms.expiry.toString(),
        isCall: terms.isCall,
        uniswapPool: terms.uniswapPool,
        creator: terms.creator,
        asset1Reserve: terms.asset1Reserve.toString(),
        asset2Reserve: terms.asset2Reserve.toString(),
    });
});

export const createOption = catchAsync(async (req, res) => {
    const { tokenId, strikePrice, premium, expiry, isCall } = req.body;

    if (!tokenId || !strikePrice || !premium || !expiry || isCall === undefined) {
        return res.status(400).json({ error: "Missing required parameters" });
    }

    const tx = await optionVaultContract.createOption(tokenId, strikePrice, premium, expiry, isCall);
    const receipt = await handleBlockchainTransaction(tx);

    res.status(200).json({
        message: "Option created successfully",
        txHash: receipt.transactionHash,
    });
});

export const buyOption = catchAsync(async (req, res) => {
    const { optionAddress, amount } = req.body;

    if (!optionAddress || !amount) {
        return res.status(400).json({ error: "Missing required parameters" });
    }

    const tx = await optionVaultContract.buyOption(optionAddress, amount);
    const receipt = await handleBlockchainTransaction(tx);

    res.status(200).json({
        message: "Option bought successfully",
        txHash: receipt.transactionHash,
    });
});

export const exerciseOption = catchAsync(async (req, res) => {
    const { optionAddress, amount } = req.body;

    if (!optionAddress || !amount) {
        return res.status(400).json({ error: "Missing required parameters" });
    }

    const tx = await optionVaultContract.exerciseOption(optionAddress, amount);
    const receipt = await handleBlockchainTransaction(tx);

    res.status(200).json({
        message: "Option exercised successfully",
        txHash: receipt.transactionHash,
    });
});

export const claimTokens = catchAsync(async (req, res) => {
    const { optionAddress } = req.body;

    if (!optionAddress) {
        return res.status(400).json({ error: "Missing required parameters" });
    }

    const tx = await optionVaultContract.claimTokens(optionAddress);
    const receipt = await handleBlockchainTransaction(tx);

    res.status(200).json({
        message: "Tokens claimed successfully",
        txHash: receipt.transactionHash,
    });
});

export const calculatePremium = catchAsync(async (req, res) => {
    const { optionAddress, amount } = req.body;

    if (!optionAddress || !amount) {
        return res.status(400).json({ error: "Missing required parameters" });
    }

    const premium = await optionVaultContract.calculatePremium(optionAddress, amount);

    res.status(200).json({
        premium: premium.toString(),
    });
});

export const getOptionByAddress = catchAsync(async (req, res) => {
    const { optionAddress } = req.params;

    if (!optionAddress) {
        return res.status(400).json({ error: "Missing required parameters" });
    }

    const optionData = await optionVaultContract.optionByAddress(optionAddress);

    res.status(200).json({
        creator: optionData.creator,
        tokenId: optionData.tokenId.toString(),
        asset1Amount: optionData.asset1Amount.toString(),
        asset2Amount: optionData.asset2Amount.toString(),
    });
});

export const getUniswapNFTManager = catchAsync(async (req, res) => {
    try {
        const nftManagerAddress = await optionVaultContract.getUniswapNFTManager();

        res.status(200).json({
            nftManagerAddress,
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

export const getUniswapV3Factory = catchAsync(async (req, res) => {
    try {
        const factoryAddress = await optionVaultContract.getUniswapV3Factory();

        res.status(200).json({
            factoryAddress,
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});
