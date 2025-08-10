const {upgrades, ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { save } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log("部署用户地址：", deployer);

  // 获取工厂合约
  const factoryDeployment = await deployments.get("NftAuctionFactory");
  const factory = await ethers.getContractAt("NftAuctionFactory", factoryDeployment.address);
  
  // 获取第一个拍卖合约地址（代理合约）
  const auctions = await factory.getAllAuctions();
  if (auctions.length === 0) {
    throw new Error("No auctions found. Please create an auction first.");
  }
  const proxyAddress = auctions[0];

  //升级合约
  const TestNftAuctionV2 = await ethers.getContractFactory("TestNftAuctionV2");
  const nftAuctionV2 = await upgrades.upgradeProxy(proxyAddress, TestNftAuctionV2);
  await nftAuctionV2.waitForDeployment();
  const proxyAddressV2 = await nftAuctionV2.getAddress();

  // 获取新的实现地址
  const newImplAddress = await upgrades.erc1967.getImplementationAddress(proxyAddressV2);
  
  console.log("升级成功！");
  console.log("代理合约地址:", proxyAddressV2);
  console.log("新实现合约地址:", newImplAddress);

  await save("NftAuctionV2", {
    abi: TestNftAuctionV2.interface.format("json"),
    address: proxyAddressV2,
    // args: [],
    // log: true,
  })

}

module.exports.tags = ["upgradeNftAuction"];
