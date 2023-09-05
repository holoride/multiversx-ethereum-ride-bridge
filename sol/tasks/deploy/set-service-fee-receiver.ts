import { task, types } from "hardhat/config";

task("set-service-fee-receiver", "Sets Service Fee Receiver on Safe")
  .addParam("receiver", "Receiver address for the service fee")
  .setAction(async (taskArgs, hre) => {
    const receiver = taskArgs.receiver;

    const [adminWallet] = await hre.ethers.getSigners();

    const filename = "setup.config.json";
    const fs = require("fs");
    let config = JSON.parse(fs.readFileSync(filename, "utf8"));
    const safeAddress = config["erc20Safe"];

    const safeContractFactory = await hre.ethers.getContractFactory("ERC20Safe");
    const safe = safeContractFactory.attach(safeAddress).connect(adminWallet);

    const tx = await safe.setServiceFeeReceiver(receiver);
    await tx.wait();
  });
