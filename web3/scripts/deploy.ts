import { ethers } from "hardhat";

async function main() {
  // Grab the contract factory 
  const UtilsLibFactory = await ethers.getContractFactory("Utils");
  const utilsContract = await UtilsLibFactory.deploy(); // Instance of the contract 

  const ContractsHandlerFactory = await ethers.getContractFactory("ContractsHandler", {libraries: {Utils: utilsContract.address}});

  // Start deployment, returning a promise that resolves to a contract object
  const handlerContract = await ContractsHandlerFactory.deploy(); // Instance of the contract 
  
  console.log("Contract deployed to address:", handlerContract.address);
}

main()
 .then(() => process.exit(0))
 .catch(error => {
   console.error(error);
   process.exit(1);
 });