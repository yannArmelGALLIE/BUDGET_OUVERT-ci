const { ethers } = require("hardhat");

async function main() {
  console.log("Déploiement de BudgetRegistry...\n");

  const [deployer] = await ethers.getSigners();
  console.log("Deployer :", deployer.address);

  const BudgetRegistry = await ethers.getContractFactory("BudgetRegistry");
  const contract = await BudgetRegistry.deploy();
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log("✅ Contrat déployé :", address);
  console.log("\n→ Copier cette adresse dans BlockchainContext.tsx :");
  console.log("   CONTRACT_ADDRESS =", `"${address}"`);

  const COMMUNE_ADMIN = ethers.keccak256(ethers.toUtf8Bytes("COMMUNE_ADMIN"));
  await contract.grantRole(COMMUNE_ADMIN, deployer.address);
  console.log("\n✅ Rôle COMMUNE_ADMIN accordé à", deployer.address);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});