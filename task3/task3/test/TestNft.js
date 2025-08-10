const { expect } = require("chai");
const { ethers, upgrades, deployments } = require("hardhat");

// 常量定义
const CCIP_ROUTER_ADDRESS = "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59";
const DURATION = 60 * 60; // 1小时
const START_PRICE = ethers.parseEther("0.01"); // 0.01 ETH

describe("TestNftAuction with Factory", function () {
  let deployer, admin, seller, buyer1, buyer2;
  let nftAuctionFactory, testNftAuction;
  let factoryAddress;
  let auctionAddress;

  // 在每个测试前部署合约
  beforeEach(async function () {
    // 获取签名者
    [deployer, admin, seller, buyer1, buyer2] = await ethers.getSigners();

    // 部署工厂合约
    await deployments.fixture(["deployNftAuctionFactory"]);
    const factoryDeployment = await deployments.get("NftAuctionFactory");
    nftAuctionFactory = await ethers.getContractAt(
      "NftAuctionFactory",
      factoryDeployment.address
    );
    factoryAddress = await nftAuctionFactory.getAddress();

    // 使用工厂合约铸造NFT给deployer（因为deployer既是管理员又是卖家）
    await nftAuctionFactory.mintNFT(deployer, "https://example.com/nft/1");

    // deployer授权工厂合约转移NFT
    await nftAuctionFactory.setApprovalForAll(factoryAddress, true);
  });

  // 测试工厂合约部署
  it("Should deploy factory contract correctly", async function () {
    const factoryAddress = await nftAuctionFactory.getAddress();
    expect(factoryAddress).to.be.properAddress;
    console.log("工厂合约地址:", factoryAddress);

    const factoryAdmin = await nftAuctionFactory.admin();
    expect(factoryAdmin).to.equal(deployer);

    const ccipRouter = await nftAuctionFactory.ccipRouter();
    expect(ccipRouter).to.equal(CCIP_ROUTER_ADDRESS);
  });

  // 测试通过工厂创建拍卖
  it("Should create auction via factory", async function () {
    // 创建拍卖 - 使用工厂合约自己作为NFT合约
    const tx = await nftAuctionFactory.connect(deployer).createAuction(
      factoryAddress,  // 使用工厂合约地址作为NFT合约
      1,              // NFT ID
      DURATION,
      START_PRICE
    );

    // 等待交易完成并获取事件
    const receipt = await tx.wait();
    // 注意：这里使用更通用的方式查找事件
    const event = receipt.logs.find(log => log.topics.length > 0);
    expect(event).to.exist;

    // 实例化拍卖合约 - 使用工厂的getAllAuctions方法获取地址
    const auctions = await nftAuctionFactory.getAllAuctions();
    expect(auctions.length).to.equal(1);
    auctionAddress = auctions[0];
    expect(auctionAddress).to.be.properAddress;

    // 实例化拍卖合约
    testNftAuction = await ethers.getContractAt("TestNftAuction", auctionAddress);

    // 验证拍卖是否创建成功
    const auctionCount = await nftAuctionFactory.getAuctionCount();
    expect(auctionCount).to.equal(1);

    console.log("拍卖合约地址:", auctionAddress);
  });

  // 测试竞拍功能
  it("Should allow bidding", async function () {
    // 先创建拍卖
    const tx = await nftAuctionFactory.connect(deployer).createAuction(
      factoryAddress,
      1,
      DURATION,
      START_PRICE
    );
    await tx.wait();

    // 获取拍卖地址
    const auctions = await nftAuctionFactory.getAllAuctions();
    auctionAddress = auctions[0];
    testNftAuction = await ethers.getContractAt("TestNftAuction", auctionAddress);

    // 买家1出价 - 修正参数数量
    const bidAmount1 = ethers.parseEther("0.02");
    await testNftAuction.connect(buyer1).bid(
      ethers.ZeroAddress, // ETH
      bidAmount1,
      { value: bidAmount1 }
    );

    // 验证出价 - 修正访问方式
    let auction = await testNftAuction.auction();
    expect(auction.highestBidder).to.equal(buyer1.address);
    expect(auction.highestPrice).to.equal(bidAmount1);

    // 买家2出价更高
    const bidAmount2 = ethers.parseEther("0.05");
    await testNftAuction.connect(buyer2).bid(
      ethers.ZeroAddress, // ETH
      bidAmount2,
      { value: bidAmount2 }
    );

    // 验证最高出价更新
    auction = await testNftAuction.auction();
    expect(auction.highestBidder).to.equal(buyer2.address);
    expect(auction.highestPrice).to.equal(bidAmount2);

    console.log("竞拍成功:", auction);
  });

  // 测试创建拍卖并铸造新NFT
  /*it("Should create auction with new NFT", async function () {
    // 创建拍卖并铸造新NFT
    const tx = await nftAuctionFactory.connect(deployer).createAuctionWithNewNFT(
      "https://example.com/nft/metadata",
      DURATION,
      START_PRICE
    );

    // 等待交易完成
    await tx.wait();

    // 验证拍卖数量
    const auctionCount = await nftAuctionFactory.getAuctionCount();
    expect(auctionCount).to.equal(1);

    // 获取创建的拍卖合约地址
    const auctions = await nftAuctionFactory.getAllAuctions();
    auctionAddress = auctions[0];
    expect(auctionAddress).to.be.properAddress;

    console.log("通过铸造新NFT创建的拍卖合约地址:", auctionAddress);
  });*/

  //测试合约升级
  it("Should upgrade the auction contract", async function () {
    // 先创建拍卖
    const tx = await nftAuctionFactory.connect(deployer).createAuction(
      factoryAddress,
      1,
      DURATION,
      START_PRICE
    );
    await tx.wait();

    // 获取拍卖地址
    const auctions = await nftAuctionFactory.getAllAuctions();
    auctionAddress = auctions[0];

    // 升级拍卖合约 测试中fixture会重置所有部署，导致找不到工厂合约地址
    //await deployments.fixture(["upgradeNftAuction"]);
              // 直接在测试中进行升级操作
         const TestNftAuction = await ethers.getContractFactory("TestNftAuction");
         const TestNftAuctionV2 = await ethers.getContractFactory("TestNftAuctionV2");
         
         // 先导入现有的代理合约到升级系统
         await upgrades.forceImport(auctionAddress, TestNftAuction, {
           constructorArgs: [CCIP_ROUTER_ADDRESS],
           unsafeAllow: ['constructor', 'state-variable-immutable'],
         });
         
         // 然后升级
         const upgradedAuction = await upgrades.upgradeProxy(auctionAddress, TestNftAuctionV2, {
           constructorArgs: [CCIP_ROUTER_ADDRESS], // 提供构造函数参数
           unsafeAllow: ['constructor', 'state-variable-immutable'], // 跳过升级安全检查
         });
         await upgradedAuction.waitForDeployment();
    // 实例化升级后的拍卖合约
    const testNftAuctionV2 = await ethers.getContractAt(
      "TestNftAuctionV2",
      auctionAddress
    );

    // 测试新功能 - 修正函数名称大小写
    const result = await testNftAuctionV2.testHello();
    console.log("成功调用升级后的testHello函数，返回值:", result);

    // 验证升级后的拍卖数据
    const auction = await testNftAuctionV2.auction();
    expect(auction.nftContract).to.equal(factoryAddress);
    expect(auction.tokenId).to.equal(1);

    console.log("拍卖合约升级成功");
  });
});