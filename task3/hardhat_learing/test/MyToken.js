const hre = require("hardhat"); //Hardhat Runtime Environment
const { expect } = require("chai"); 


describe("MyToken Test",async() => {

        const{ethers} = hre //js的结构语法

        const initialSupply = 10000;

        let MyTokenContract;

        let account1,account2;

        //async和await
        //await 将异步操作相对转为同步的
        beforeEach(async() => {
 
       [account1,account2] = await ethers.getSigners();

        const MyToken = await ethers.getContractFactory("MyToken");

        MyTokenContract = await MyToken.connect(account2).deploy(initialSupply);


        MyTokenContract.waitForDeployment();

        const contractAddress = await MyTokenContract.getAddress();

        expect(contractAddress).to.length.greaterThan(0);
        //console.log(contractAddress,"==contractAddress==");
    })

    it("验证合约的name,symbol,decimal",async() => {
        const name = await MyTokenContract.name();
        const symbol = await MyTokenContract.symbol();
        const decimals = await MyTokenContract.decimals();
        expect(name).to.equal("MyToken");
        expect(symbol).to.equal("MTK");
        expect(decimals).to.equal(18);
    })

    it("验证合约的转账",async() => {
        // const balanceOfAccount1 = await MyTokenContract.balanceOf(account1.address);
        // expect(balanceOfAccount1).to.equal(initialSupply);
        const req =await MyTokenContract.transfer(account1,initialSupply/2);

        console.log(req,"==req==");

        const balanceOfAccount2 = await MyTokenContract.balanceOf(account2);
        expect(balanceOfAccount2).to.equal(initialSupply/2);

    })
})