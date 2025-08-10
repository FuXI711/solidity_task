const { deployments, upgrades, ethers } = require("hardhat");

const fs = require("fs");
const path = require("path");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { save } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log("部署用户地址：", deployer);
  // 修正合约名称
  const TestNftAuction = await ethers.getContractFactory("TestNftAuction");
  
  // 提供正确的初始化参数
  const ccipRouterAddress = "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59"; // 与工厂合约一致
  const TestNftAuctionProxy = await upgrades.deployProxy(TestNftAuction, [deployer, ccipRouterAddress], {
    initializer: "initialize",
    constructorArgs: [ccipRouterAddress], // 添加构造函数参数
  })
  
  await TestNftAuctionProxy.waitForDeployment();

  const proxyAddress = await TestNftAuctionProxy.getAddress()
  console.log("代理合约地址：", proxyAddress);
  const implAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress)
  console.log("实现合约地址：", implAddress);
  
  const storePath = path.resolve(__dirname, "./.cache/proxyTestNftAuction.json");

  
  fs.writeFileSync(
    storePath,
    JSON.stringify({
      proxyAddress,
      implAddress,
      abi: TestNftAuction.interface.format("json"),
    })
  );

  await save("TestNftAuctionProxy", {
    abi: TestNftAuction.interface.format("json"),
    address: proxyAddress,
    // args: [],
    // log: true,
  })
//   await deploy("MyContract", {
//     from: deployer,
//     args: ["Hello"],
//     log: true,
//   });
};


module.exports.tags = ["depolyNftAuction"];