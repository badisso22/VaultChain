import fs from "fs";
import { ethers } from "ethers";

const ALCHEMY_RPC_URL = process.env.ALCHEMY_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

async function main() {
  const provider = new ethers.JsonRpcProvider(ALCHEMY_RPC_URL);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

  console.log("Deploying with wallet:", wallet.address);
  const balance = await provider.getBalance(wallet.address);
  console.log("Balance:", ethers.formatEther(balance), "ETH");

  console.log("\nDeploying vaultRoom...");
  const vaultRoomArtifact = JSON.parse(fs.readFileSync("./artifacts/contracts/vaultRoom.sol/vaultRoom.json", "utf8"));
  const vaultRoomFactory = new ethers.ContractFactory(vaultRoomArtifact.abi, vaultRoomArtifact.bytecode, wallet);
  const vaultRoom = await vaultRoomFactory.deploy();
  await vaultRoom.waitForDeployment();
  const vaultRoomAddress = await vaultRoom.getAddress();
  console.log("vaultRoom:", vaultRoomAddress);

  console.log("\nDeploying fileRegistry...");
  const fileRegistryArtifact = JSON.parse(fs.readFileSync("./artifacts/contracts/fileRegistry.sol/fileRegistry.json", "utf8"));
  const fileRegistryFactory = new ethers.ContractFactory(fileRegistryArtifact.abi, fileRegistryArtifact.bytecode, wallet);
  const fileRegistry = await fileRegistryFactory.deploy(vaultRoomAddress);
  await fileRegistry.waitForDeployment();
  const fileRegistryAddress = await fileRegistry.getAddress();
  console.log("fileRegistry:", fileRegistryAddress);

  const deployments = {
    network: "sepolia",
    deployedAt: new Date().toISOString(),
    deployer: wallet.address,
    contracts: {
      vaultRoom: vaultRoomAddress,
      fileRegistry: fileRegistryAddress,
    }
  };

  fs.writeFileSync("./deployments.json", JSON.stringify(deployments, null, 2));

  console.log("\n✅ All contracts deployed!");
  console.log("vaultRoom:    ", vaultRoomAddress);
  console.log("fileRegistry: ", fileRegistryAddress);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});