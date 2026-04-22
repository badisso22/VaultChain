import fs from "fs";
import { ethers } from "ethers";
import { readFileSync } from "fs";
const envFile = readFileSync(".env", "utf8");
const envVars = Object.fromEntries(
  envFile
    .split("\n")
    .filter(line => line.includes("="))
    .map(line => [line.split("=")[0].trim(), line.split("=").slice(1).join("=").trim()])
);
const ALCHEMY_RPC_URL = envVars.ALCHEMY_RPC_URL;
const PRIVATE_KEY = envVars.PRIVATE_KEY;

async function main() {

  const provider = new ethers.JsonRpcProvider(ALCHEMY_RPC_URL);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

  console.log("Deploying with wallet:", wallet.address);

  const balance = await provider.getBalance(wallet.address);
  console.log("Balance:", ethers.formatEther(balance), "ETH");

  console.log("\nDeploying vaultRegistry...");
  const registryArtifact = JSON.parse(fs.readFileSync("./artifacts/contracts/vaultRegistry.sol/vaultRegistry.json", "utf8"));
  const registryFactory = new ethers.ContractFactory(registryArtifact.abi, registryArtifact.bytecode, wallet);
  const registry = await registryFactory.deploy();
  await registry.waitForDeployment();
  const registryAddress = await registry.getAddress();
  console.log("vaultRegistry:", registryAddress);

  console.log("\nDeploying auditLog...");
  const auditArtifact = JSON.parse(fs.readFileSync("./artifacts/contracts/auditLog.sol/auditLog.json", "utf8"));
  const auditFactory = new ethers.ContractFactory(auditArtifact.abi, auditArtifact.bytecode, wallet);
  const audit = await auditFactory.deploy();
  await audit.waitForDeployment();
  const auditAddress = await audit.getAddress();
  console.log("auditLog:", auditAddress);

  console.log("\nDeploying chambers...");
  const chambersArtifact = JSON.parse(fs.readFileSync("./artifacts/contracts/chambers.sol/chambers.json", "utf8"));
  const chambersFactory = new ethers.ContractFactory(chambersArtifact.abi, chambersArtifact.bytecode, wallet);
  const chambersContract = await chambersFactory.deploy(registryAddress, auditAddress);
  await chambersContract.waitForDeployment();
  const chambersAddress = await chambersContract.getAddress();
  console.log("chambers:", chambersAddress);

  console.log("\nDeploying trustScore...");
  const trustArtifact = JSON.parse(fs.readFileSync("./artifacts/contracts/trustScore.sol/trustScore.json", "utf8"));
  const trustFactory = new ethers.ContractFactory(trustArtifact.abi, trustArtifact.bytecode, wallet);
  const trust = await trustFactory.deploy(registryAddress);
  await trust.waitForDeployment();
  const trustAddress = await trust.getAddress();
  console.log("trustScore:", trustAddress);

  console.log("\nLinking contracts...");
  const auditContract = new ethers.Contract(auditAddress, auditArtifact.abi, wallet);
  await auditContract.setAuthorizedContracts(registryAddress, chambersAddress);
  console.log("Contracts linked!");

  const deployments = {
    network: "sepolia",
    deployedAt: new Date().toISOString(),
    deployer: wallet.address,
    contracts: {
      vaultRegistry: registryAddress,
      auditLog: auditAddress,
      chambers: chambersAddress,
      trustScore: trustAddress,
    }
  };

  fs.writeFileSync("./deployments.json", JSON.stringify(deployments, null, 2));

  console.log("\n✅ All contracts deployed!");
  console.log("📄 Addresses saved to deployments.json");
  console.log("\nContract Addresses:");
  console.log("  vaultRegistry:", registryAddress);
  console.log("  auditLog:     ", auditAddress);
  console.log("  chambers:     ", chambersAddress);
  console.log("  trustScore:   ", trustAddress);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});