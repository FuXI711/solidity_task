require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("@openzeppelin/hardhat-upgrades");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  namedAccounts: {
    deployer: {
      default: 0,
      user1: 1,
      user2: 2,
    },
  },
};

//   //0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238    chainlink 查询地址
        //0x694AA1769357215DE4FAC081bf1f309aDC325306    eth/usd价格