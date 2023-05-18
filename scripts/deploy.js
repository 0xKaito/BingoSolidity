const { ethers, upgrades } = require("hardhat");

async function main() {

  const Token = await ethers.getContractFactory("BingoToken");
  const token = await Token.deploy();
  const Bingo = await ethers.getContractFactory("Bingo");
  const bingo = await Bingo.deploy(token.address, 100, 10, 10);
  await bingo.deployed();
  console.log("Bingo deployed to:", bingo.address);
}

main();