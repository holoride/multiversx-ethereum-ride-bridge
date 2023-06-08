import { task } from "hardhat/config";
import { getDeployOptions } from "./args/deployOptions";

task("init-supply", "Deposit the initial supply on a new SC from an old one")
  .addParam("amount", "New amount we want to set (full value, with 18 decimals)")
  .addOptionalParam("price", "Gas price in gwei for this transaction", undefined)
  .setAction(async (taskArgs, hre) => {
    const [adminWallet] = await hre.ethers.getSigners();
    const fs = require("fs");
    const amount = taskArgs.amount;
    const config = JSON.parse(fs.readFileSync("setup.config.json", "utf8"));
    const safeAddress = config["erc20Safe"];
    const token = Object.keys(config["tokens"][0])[0];
    const safeContractFactory = await hre.ethers.getContractFactory("ERC20Safe");
    const safe = safeContractFactory.attach(safeAddress).connect(adminWallet);
    const tokenContract = 
        (await hre.ethers.getContractFactory("GenericERC20"))
        .attach(token)
        .connect(adminWallet);
    
    await tokenContract.approve(
      safeAddress,
      "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
      getDeployOptions(taskArgs),
    );
    await safe.initSupply(token, amount, getDeployOptions(taskArgs));
  });
