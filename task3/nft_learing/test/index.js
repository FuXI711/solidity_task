const { ethers, deployments,upgrades } = require("hardhat")
const {expect} = require("chai")


describe("Test upgrade", async function () {
    it("should be able to deploy", async function () {
       //1.部署实现合约
        await deployments.fixture("depolyNftAuction")
        const nftAuctionProxy = await deployments.get("NftAuctionProxy")

       //2.调用createAuction 方法创建拍卖
       const nftAuction = await ethers.getContractAt("NftAuction",nftAuctionProxy.address)

       await nftAuction.createAuction(
            100 * 1000,
            ethers.parseEther("0.01"),
            ethers.ZeroAddress,
            1
        );

        const auction = await nftAuction.auctions(0);

        const implAddress1 = await upgrades.erc1967.getImplementationAddress(nftAuctionProxy.address)
      

        //3.升级合约
         await deployments.fixture("upgradeNftAuction")
        //重新读取升级后的数据
        const auction2 = await nftAuction.auctions(0); 
        const implAddress2 = await upgrades.erc1967.getImplementationAddress(nftAuctionProxy.address)

        const nftAuction2 = await ethers.getContractAt("NftAuctionV2",nftAuctionProxy.address)
       const hello = await nftAuction2.testHello()
       console.log("1>>>>>>>>>>:",hello);
       
        expect(auction2.startTime).to.equal(auction.startTime);
        expect(implAddress1).to.not.equal(implAddress2)

    })
})
