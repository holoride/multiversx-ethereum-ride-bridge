import { task } from "hardhat/config";
import { ethers } from "ethers";

task("deploy-whitelist-token", "Deploys ERC20 contract to use to test the bridge, and whitelists it").setAction(async (_, hre) => {
  const [deployer] = await hre.ethers.getSigners();
  const fs = require("fs");
  const filename = "setup.config.json";
  const config = JSON.parse(fs.readFileSync(filename, "utf8"));
  console.log("Current contract addresses");
  const safeAddress = config["erc20Safe"];
  const safeContractFactory = await hre.ethers.getContractFactory("ERC20Safe");
  const safe = safeContractFactory.attach(safeAddress);
  console.log("Safe at: ", safe.address);
  // deploy contracts
  const genericERC20Factory = await hre.ethers.getContractFactory("GenericERC20");

  const xContract = await genericERC20Factory.deploy("Wrapped RTest", "WRTEST");
  await xContract.deployed();

  const address = xContract.address;

  //whitelist tokens in safe
  console.log("Whitelisting token ", address);
  const minAmount = hre.ethers.constants.Zero.toHexString();
  const maxAmount = hre.ethers.constants.MaxUint256.toHexString();
  await safe.whitelistToken(address, minAmount, maxAmount);

  if (config.tokens === undefined) {
    config.tokens = {};
  }
  config.tokens.push({ [address]: { min: minAmount, max: maxAmount } });
  fs.writeFileSync(filename, JSON.stringify(config));
  console.log("Token whitelisted: ", address);
});
