const {upgrades, ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { save } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log("部署用户地址：", deployer);

  //读取
  const storePath = path.resolve(__dirname, "./.cache/proxyNftAuction.json");
  const storedData = fs.readFileSync(storePath, "utf8");
  const{proxyAddress,implAddress,abi} = JSON.parse(storedData);

  //升级合约
  const NftAuctionV2 = await ethers.getContractFactory("NftAuctionV2");
  const nftAuctionV2 = await upgrades.upgradeProxy(proxyAddress, NftAuctionV2);
  await nftAuctionV2.waitForDeployment();
  const proxyAddressV2 = await nftAuctionV2.getAddress();

  fs.writeFileSync(
    storePath,
    JSON.stringify({
      proxyAddress: proxyAddressV2,
      implAddress,
      abi: NftAuctionV2.interface.format("json"),
    })
  );

  await save("NftAuctionV2", {
    abi: NftAuctionV2.interface.format("json"),
    address: proxyAddressV2,
    // args: [],
    // log: true,
  })

}

module.exports.tags = ["upgradeNftAuction"];
