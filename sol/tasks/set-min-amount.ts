import { task } from "hardhat/config";
import { ethers } from "ethers";
import { getDeployOptions } from "./args/deployOptions";

task("set-min-amount", "Updates minimum amount for depositing an ERC20 token")
  .addParam("amount", "New amount we want to set (full value, with 18 decimals)")
  .addOptionalParam("price", "Gas price in gwei for this transaction", undefined)
  .setAction(async (taskArgs, hre) => {
    const amount = taskArgs.amount;

    const [adminWallet] = await hre.ethers.getSigners();
    const fs = require("fs");
    const config = JSON.parse(fs.readFileSync("setup.config.json", "utf8"));
    const safeAddress = config["erc20Safe"];
    const tokenAddress = Object.keys(config["tokens"][0])[0];
    const safeContractFactory = await hre.ethers.getContractFactory("ERC20Safe");
    const safe = safeContractFactory.attach(safeAddress).connect(adminWallet);
    await safe.setTokenMinLimit(tokenAddress, amount, getDeployOptions(taskArgs));
  });
