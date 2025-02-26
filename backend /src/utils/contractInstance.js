import { ethers } from 'ethers';
import dotenv from 'dotenv';
import { OPTION_VAULT_CONTRACT_ABI, OPTION_TOKEN_CONTRACT_ABI } from '../utils/constants.js';

dotenv.config();

const {
  INFURA_SEPOLIA_API_KEY,
  PRIVATE_KEY,
  OPTION_VAULT_CONTRACT_ADDRESS,
  OPTION_TOKEN_CONTRACT_ADDRESS,
} = process.env;

if (
  !INFURA_SEPOLIA_API_KEY ||
  !PRIVATE_KEY ||
  !OPTION_VAULT_CONTRACT_ADDRESS ||
  !OPTION_TOKEN_CONTRACT_ADDRESS
) {
  throw new Error(
    'Missing one or more required environment variables: INFURA_SEPOLIA_API_KEY, PRIVATE_KEY, CONTRACT_ADDRESS'
  );
}

const provider = new ethers.InfuraProvider('sepolia', INFURA_SEPOLIA_API_KEY);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

const optionVaultContract = new ethers.Contract(
  OPTION_VAULT_CONTRACT_ADDRESS,
  OPTION_VAULT_CONTRACT_ABI,
  wallet
);

const optionTokenContract = new ethers.Contract(
  OPTION_TOKEN_CONTRACT_ADDRESS,
  OPTION_TOKEN_CONTRACT_ABI,
  wallet
);

export { optionVaultContract, optionTokenContract, wallet, provider };
