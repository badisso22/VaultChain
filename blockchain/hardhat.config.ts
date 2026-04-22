import { defineConfig } from "hardhat/config";
import * as dotenv from "dotenv";
dotenv.config();

export default defineConfig({
  solidity: {
    version: "0.8.28",
  },
  networks: {
    sepolia: {
      type: "http",
      url: process.env.ALCHEMY_RPC_URL ?? "",
      accounts: process.env.PRIVATE_KEY 
        ? [process.env.PRIVATE_KEY] 
        : [],
    },
  },
});