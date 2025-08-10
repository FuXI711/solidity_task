const { deployments, upgrades, ethers } = require("hardhat");

const fs = require("fs");
const path = require("path");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, save } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log("部署用户地址：", deployer);
  
  // CCIP路由地址
  const ccipRouterAddress = "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59";
  
  // 首先部署拍卖合约实现
  console.log("部署拍卖合约实现...");
  const TestNftAuction = await ethers.getContractFactory("TestNftAuction");
  const auctionImplementation = await deploy("TestNftAuction", {
    from: deployer,
    args: [ccipRouterAddress], // 实现合约需要CCIP路由地址
    log: true,
  });
  
  console.log("拍卖合约实现地址：", auctionImplementation.address);

  // 然后部署工厂合约
  console.log("部署工厂合约...");
  const NftAuctionFactory = await ethers.getContractFactory("NftAuctionFactory");
  const nftAuctionFactory = await deploy("NftAuctionFactory", {
    from: deployer,
    args: [ccipRouterAddress, auctionImplementation.address], // 传递CCIP路由和实现合约地址
    log: true,
  });

  const contractAddress = nftAuctionFactory.address;
  console.log("工厂合约地址：", contractAddress);

  const storePath = path.resolve(__dirname, "./.cache/nftAuctionFactory.json");

  fs.writeFileSync(
    storePath,
    JSON.stringify({
      address: contractAddress,
      abi: NftAuctionFactory.interface.format("json"),
    })
  );

  await save("NftAuctionFactory", {
    abi: NftAuctionFactory.interface.format("json"),
    address: contractAddress,
    args: [ccipRouterAddress, auctionImplementation.address], // 与上面的参数保持一致
    log: true,
  });
};


module.exports.tags = ["deployNftAuctionFactory"];