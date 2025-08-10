# NFT拍卖系统技术文档

## 1. 系统概述

本系统是一个基于以太坊的NFT拍卖平台，支持跨链竞拍功能。系统采用工厂模式设计，支持合约升级，具备完整的拍卖流程管理。

### 1.1 核心特性
- ✅ NFT拍卖管理
- ✅ 跨链竞拍支持（CCIP）
- ✅ 价格预言机集成
- ✅ 合约可升级性
- ✅ 工厂模式部署
- ✅ 多代币支持（ETH/ERC20）

### 1.2 技术栈
- **区块链**: Ethereum
- **开发框架**: Hardhat
- **合约语言**: Solidity 0.8.0+
- **跨链协议**: Chainlink CCIP
- **价格预言机**: Chainlink Price Feeds
- **代理模式**: OpenZeppelin UUPS

## 2. 系统架构

### 2.1 合约架构图
```
┌─────────────────────────────────────────────────────────────┐
│                    NFT拍卖系统架构                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   NftAuction    │    │  TestNftAuction │                │
│  │    Factory      │    │      V2         │                │
│  │                 │    │                 │                │
│  │ • 工厂管理       │    │ • 升级版本       │                │
│  │ • NFT铸造       │    │ • 新功能        │                │
│  │ • 拍卖创建       │    │ • 数据保持      │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       ▲                        │
│           │                       │                        │
│           ▼                       │                        │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │  TestNftAuction │    │   ERC1967Proxy  │                │
│  │  (Implementation)│   │                 │                │
│  │                 │    │ • 代理合约      │                │
│  │ • 拍卖逻辑       │    │ • 数据存储      │                │
│  │ • 竞拍功能       │    │ • 接口转发      │                │
│  │ • 跨链支持       │    └─────────────────┘                │
│  └─────────────────┘                                       │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   Chainlink     │    │   Price Feeds   │                │
│  │     CCIP        │    │                 │                │
│  │                 │    │ • 价格查询      │                │
│  │ • 跨链通信       │    │ • 代币汇率      │                │
│  │ • 消息传递       │    │ • 价值计算      │                │
│  └─────────────────┘    └─────────────────┘                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 合约关系图
```
用户交互流程:
用户 → Factory → 创建代理合约 → 拍卖合约 → CCIP/Price Feeds

数据流向:
NFT → Factory → 代理合约 → 拍卖合约 → 买家/卖家

升级流程:
V1实现 → 代理合约 → V2实现 (数据保持)
```

## 3. 合约详细说明

### 3.1 NftAuctionFactory.sol

#### 功能描述
工厂合约负责管理整个拍卖系统，包括NFT铸造、拍卖创建和合约管理。

#### 核心功能
```solidity
// 主要接口
function mintNFT(address to, string memory uri) → uint256
function createAuction(address _nftAddress, uint256 _tokenId, uint256 _during, uint256 _startPrice) → address
function createAuctionWithNewNFT(string memory uri, uint256 _during, uint256 _startPrice) → (address, uint256)
function getAllAuctions() → TestNftAuction[]
function getAuctionCount() → uint256
```

#### 状态变量
- `auctions[]`: 所有拍卖合约地址数组
- `isAuctionContract`: 地址到拍卖合约的映射
- `admin`: 管理员地址
- `ccipRouter`: CCIP路由地址
- `auctionImplementation`: 拍卖合约实现地址

### 3.2 TestNftAuction.sol

#### 功能描述
拍卖合约的核心逻辑实现，包含完整的拍卖流程和跨链功能。

#### 核心功能
```solidity
// 拍卖管理
function setAuctionParameters(address _nftAddress, uint256 _tokenId, uint256 _during, uint256 _startPrice)
function startAuction()
function bid(address _nftAddress, uint256 _amount)
function endAuction()

// 跨链功能
function crossChainBid(uint64 destinationChainId, address _nftAddress, uint256 _amount)
function addSupportedChain(uint64 chainId)

// 价格预言机
function setPriceFeed(address _nftAddress, address _priceFeed)
function getPrice(address _nftAddress) → int
```

#### 数据结构
```solidity
struct Auction {
    address seller;           // 卖家地址
    uint256 during;           // 拍卖持续时间
    uint256 startPrice;       // 起拍价格
    uint256 startTime;        // 开始时间戳
    uint256 highestPrice;     // 当前最高出价
    address highestBidder;    // 当前最高出价者
    bool ended;               // 是否已结束
    address nftContract;      // NFT合约地址
    uint256 tokenId;          // NFT tokenId
    address tokenAddress;     // 竞拍代币类型
}
```

### 3.3 TestNftAuctionV2.sol

#### 功能描述
拍卖合约的升级版本，在保持原有功能的基础上添加新特性。

#### 新增功能
```solidity
function testHello() → string memory
```

## 4. 功能流程说明

### 4.1 拍卖创建流程
```
1. 管理员调用Factory.createAuction()
2. Factory验证参数和权限
3. Factory创建ERC1967Proxy代理合约
4. 代理合约调用实现合约的initialize()
5. 设置拍卖参数并开始拍卖
6. 转移NFT到拍卖合约
7. 记录拍卖合约地址
```

### 4.2 竞拍流程
```
1. 用户调用bid()函数
2. 验证拍卖状态和时间
3. 计算统一价值（考虑价格预言机）
4. 验证出价有效性
5. 转移代币到合约
6. 退还上一个最高出价者
7. 更新拍卖信息
```

### 4.3 跨链竞拍流程
```
1. 用户调用crossChainBid()
2. 验证目标链支持
3. 准备CCIP消息
4. 计算跨链费用
5. 发送跨链消息
6. 目标链接收并处理竞拍
```

### 4.4 拍卖结束流程
```
1. 验证拍卖时间已到期
2. 检查是否有最高出价者
3. 如果有出价者：
   - 转移NFT给最高出价者
   - 转移资金给卖家
4. 如果没有出价者：
   - 退还NFT给卖家
5. 标记拍卖结束
```

### 4.5 合约升级流程
```
1. 部署新的实现合约V2
2. 调用upgradeProxy()升级代理合约
3. 验证数据保持完整
4. 测试新功能可用
```

## 5. 部署步骤

### 5.1 环境准备
```bash
# 安装依赖
npm install

# 编译合约
npx hardhat compile

# 启动本地节点（可选）
npx hardhat node
```

### 5.2 部署配置
```javascript
// hardhat.config.js 配置
module.exports = {
  solidity: "0.8.20",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    sepolia: {
      url: process.env.SEPOLIA_URL,
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};
```

### 5.3 部署脚本执行
```bash
# 部署工厂合约和实现合约
npx hardhat run deploy/01_deploy_nft_auctionFactory.js --network localhost

# 创建拍卖（可选）
npx hardhat run deploy/01_deploy_nft_auction.js --network localhost

# 升级合约（可选）
npx hardhat run deploy/02_deploy_nft_auction.js --network localhost
```

### 5.4 Remix部署步骤

#### 步骤1：部署实现合约
1. 编译`TestNftAuction.sol`
2. 部署参数：`0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59`（CCIP路由地址）
3. 记录实现合约地址

#### 步骤2：部署工厂合约
1. 编译`NftAuctionFactory.sol`
2. 部署参数：
   - `_ccipRouter`: `0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59`
   - `_auctionImplementation`: 步骤1的实现合约地址

#### 步骤3：创建拍卖
1. 调用工厂合约的`mintNFT()`铸造NFT
2. 调用`createAuction()`创建拍卖
3. 使用`getAllAuctions()`获取代理合约地址

#### 步骤4：测试拍卖功能
1. 在"At Address"中输入代理合约地址
2. 选择`TestNftAuction`合约
3. 测试所有拍卖功能

## 6. 测试用例

### 6.1 单元测试
```bash
# 运行所有测试
npx hardhat test

# 运行特定测试
npx hardhat test test/TestNft.js
```

### 6.2 测试覆盖
- ✅ 工厂合约部署测试
- ✅ 拍卖创建测试
- ✅ 竞拍功能测试
- ✅ 跨链功能测试
- ✅ 合约升级测试
- ✅ 价格预言机测试

## 7. 安全考虑

### 7.1 权限控制
- 只有管理员可以创建拍卖
- 只有管理员可以升级合约
- 只有管理员可以添加支持的链

### 7.2 重入攻击防护
- 使用OpenZeppelin的安全库
- 状态更新在外部调用之前

### 7.3 价格操纵防护
- 使用Chainlink价格预言机
- 支持多代币价格查询

### 7.4 升级安全
- 使用UUPS代理模式
- 数据与逻辑分离
- 升级权限控制

## 8. 配置参数

### 8.1 网络配置
```javascript
const NETWORKS = {
  localhost: {
    ccipRouter: "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59",
    chainId: 31337
  },
  sepolia: {
    ccipRouter: "0xD0daae2231E9CB96b94C8512223533293C3693Bf",
    chainId: 11155111
  }
};
```

### 8.2 拍卖参数
```javascript
const AUCTION_PARAMS = {
  minDuration: 10,           // 最小拍卖时长（秒）
  minStartPrice: 1,          // 最小起拍价（wei）
  defaultDuration: 3600,     // 默认拍卖时长（1小时）
  defaultStartPrice: "10000000000000000"  // 默认起拍价（0.01 ETH）
};
```

## 9. 故障排除

### 9.1 常见问题
1. **部署失败**: 检查网络连接和账户余额
2. **拍卖创建失败**: 验证NFT所有权和授权
3. **竞拍失败**: 检查拍卖状态和出价金额
4. **升级失败**: 确认升级权限和合约兼容性

### 9.2 调试工具
```bash
# 查看合约日志
npx hardhat console

# 验证合约
npx hardhat verify --network sepolia CONTRACT_ADDRESS

# 查看部署信息
npx hardhat run scripts/deploy-info.js
```

## 10. 扩展功能

### 10.1 计划功能
- [ ] 批量拍卖支持
- [ ] 拍卖模板系统
- [ ] 高级竞价策略
- [ ] 拍卖历史记录
- [ ] 用户信誉系统

### 10.2 集成建议
- 前端界面开发
- 移动端应用
- 数据分析面板
- 多链支持扩展

---

**文档版本**: v1.0  
**最后更新**: 2024年  
**维护者**: 开发团队
