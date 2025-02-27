import express from "express";
import {
  initializeOption,
  adminTransfer,
  burnOption,
  calculateProfit,
  getAsset1Price,
  convertAsset2ToAsset1,
  getOptionTerms,
  createOption,
  buyOption,
  exerciseOption,
  claimTokens,
  calculatePremium,
  getOptionByAddress,
  getUniswapNFTManager,
  getUniswapV3Factory
} from "../controllers/controllers.js";

const router = express.Router();

// OptionToken Routes
router.post("/options", initializeOption);
router.post("/option/admin-transfer", adminTransfer);
router.post("/option/burn", burnOption);
router.post("/option/calculate-profit", calculateProfit);
router.get("/option/asset1-price", getAsset1Price);
router.post("/option/convert-asset2-to-asset1", convertAsset2ToAsset1);
router.get("/option/terms", getOptionTerms);

// OptionsVault Routes
router.post("/vault/options", createOption);
router.post("/vault/options/buy", buyOption);
router.post("/vault/options/exercise", exerciseOption);
router.post("/vault/options/claim", claimTokens);
router.get("/vault/options/:optionAddress/premium", calculatePremium);
router.get("/vault/options/:optionAddress", getOptionByAddress);

// Uniswap Utility Routes
router.get("/vault/uniswap-nft-manager", getUniswapNFTManager);
router.get("/vault/uniswap-factory", getUniswapV3Factory);

export default router;
