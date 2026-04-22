import hre from "hardhat";
import fs from "fs";

async function main() {

  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with wallet:", deployer.address);

  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("Wallet balance:", hre.ethers.formatEther(balance), "ETH");

  // Step 1: Deploy vaultRegistry 
  console.log("\n Deploying vaultRegistry...");
  const registryFactory = await hre.ethers.getContractFactory("vaultRegistry");
  const registry = await registryFactory.deploy();
  await registry.waitForDeployment();
  const registryAddress = await registry.getAddress();
  console.log("vaultRegistry deployed to:", registryAddress);

  // Step 2: Deploy auditLog 
  console.log("\n Deploying auditLog...");
  const auditFactory = await hre.ethers.getContractFactory("auditLog");
  const audit = await auditFactory.deploy();
  await audit.waitForDeployment();
  const auditAddress = await audit.getAddress();
  console.log("auditLog deployed to:", auditAddress);

  // Step 3: Deploy chambers 
  console.log("\n Deploying chambers...");
  const chambersFactory = await hre.ethers.getContractFactory("chambers");
  const chambersContract = await chambersFactory.deploy(registryAddress, auditAddress);
  await chambersContract.waitForDeployment();
  const chambersAddress = await chambersContract.getAddress();
  console.log("chambers deployed to:", chambersAddress);

  // Step 4: Deploy trustScore 
  console.log("\n Deploying trustScore...");
  const trustFactory = await hre.ethers.getContractFactory("trustScore");
  const trust = await trustFactory.deploy(registryAddress);
  await trust.waitForDeployment();
  const trustAddress = await trust.getAddress();
  console.log("trustScore deployed to:", trustAddress);

  // Step 5: Link contracts together 
  console.log("\n Linking contracts...");
  await audit.setAuthorizedContracts(registryAddress, chambersAddress);
  console.log("auditLog authorized contracts set");

  // Step 6: Save all addresses to a JSON file 
  const deployments = {
    network: "sepolia",
    deployedAt: new Date().toISOString(),
    deployer: deployer.address,
    contracts: {
      vaultRegistry: registryAddress,
      auditLog: auditAddress,
      chambers: chambersAddress,
      trustScore: trustAddress,
    }
  };

  fs.writeFileSync(
    "./deployments.json",
    JSON.stringify(deployments, null, 2)
  );

  console.log("\n All contracts deployed successfully!");
  console.log("Addresses saved to deployments.json");
  console.log("\n Contract Addresses:");
  console.log("  vaultRegistry:", registryAddress);
  console.log("  auditLog:     ", auditAddress);
  console.log("  chambers:     ", chambersAddress);
  console.log("  trustScore:   ", trustAddress);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});