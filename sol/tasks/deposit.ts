import { task } from "hardhat/config";
import { getDeployOptions } from "./args/deployOptions";

task("deposit", "Deposits token and sends to safe")
  .addParam("amount", "Amount we want to deposit (full value, with decimals)")
  .addParam("receiver", "Multiversx address hex encoded of the receiver")
  .addOptionalParam("price", "Gas price in gwei for this transaction", undefined)
  .setAction(async (taskArgs, hre) => {
    const fs = require("fs");
    const filename = "setup.config.json";
    let config = JSON.parse(fs.readFileSync(filename, "utf8"));
    const [adminWallet] = await hre.ethers.getSigners();
    const safeAddress = config["erc20Safe"];
    const safeContractFactory = await hre.ethers.getContractFactory("ERC20Safe");
    const safe = safeContractFactory.attach(safeAddress).connect(adminWallet);

    const address = Object.keys(config["tokens"][0])[0];
    const amount = taskArgs.amount;
    const receiver = taskArgs.receiver;
    console.log("receiver: ", receiver);

    await safe.deposit(address, amount, Buffer.from(receiver, "hex"), getDeployOptions(taskArgs));
  });
