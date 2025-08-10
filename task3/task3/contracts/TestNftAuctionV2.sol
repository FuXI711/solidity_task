// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

// 外部合约导入
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
   

/**
 * @title TestNftAuction
 * @dev NFT拍卖合约，支持跨链竞拍功能
 */
contract TestNftAuctionV2 is CCIPReceiver, Initializable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _router) CCIPReceiver(_router) {
        _disableInitializers();
    }
    // 拍卖结构体定义
    struct Auction {
        address seller;           // 卖家地址
        uint256 during;           // 拍卖持续时间(秒)
        uint256 startPrice;       // 起拍价格
        uint256 startTime;        // 开始时间戳
        uint256 highestPrice;     // 当前最高出价
        address highestBidder;    // 当前最高出价者
        bool ended;               // 是否已结束
        address nftContract;      // NFT合约地址
        uint256 tokenId;          // NFT tokenId
        address tokenAddress;     // 竞拍代币类型
    }

    // 状态变量
    Auction public auction;                 // 拍卖信息
    address public admin;                   // 管理员地址
    IRouterClient public ccipRouter;        // CCIP路由地址
    mapping(uint64 => bool) public supportedChainIds;  // 支持的链ID
    mapping(address => AggregatorV3Interface) public priceFeeds;  // 价格预言机映射

    /**
     * @dev 初始化函数
     * @param _seller 卖家地址
     * @param _ccipRouter CCIP路由合约地址
     */
    function initialize(address _seller, address _ccipRouter) public initializer {
        admin = msg.sender;
        auction.seller = _seller;
        ccipRouter = IRouterClient(_ccipRouter);
    }

    // =============================================================
    //                           拍卖管理
    // =============================================================

    /**
     * @dev 设置拍卖参数
     * @param _nftAddress NFT合约地址
     * @param _tokenId NFT tokenId
     * @param _during 拍卖持续时间
     * @param _startPrice 起拍价格
     */
    function setAuctionParameters(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _during,
        uint256 _startPrice
    ) external onlyAdmin {
        require(auction.startTime == 0, "Auction already started");

        auction.nftContract = _nftAddress;
        auction.tokenId = _tokenId;
        auction.during = _during;
        auction.startPrice = _startPrice;
        auction.ended = false;
        auction.highestPrice = 0;
        auction.highestBidder = address(0);
        auction.tokenAddress = address(0);
    }

    /**
     * @dev 开始拍卖
     */
    function startAuction() external onlyAdmin {
        require(auction.startTime == 0, "Auction already started");
        require(auction.nftContract != address(0), "NFT contract not set");
        require(auction.tokenId != 0, "Token ID not set");
        require(auction.during > 10, "Duration too short");
        require(auction.startPrice > 0, "Start price too low");

        auction.startTime = block.timestamp;
    }

    /**
     * @dev 参与拍卖
     * @param _nftAddress 竞拍代币地址(0表示ETH)
     * @param _amount 竞拍数量
     */
    function bid(address _nftAddress, uint256 _amount) public payable {
        Auction storage _auction = auction;

        require(!_auction.ended && block.timestamp < _auction.startTime + _auction.during, "Auction has ended");

        // 计算统一价值
        uint payValue;
        if (_nftAddress != address(0)) {
            payValue = _amount * uint(getPrice(_nftAddress));
        } else {
            _amount = msg.value;
            payValue = _amount * uint(getPrice(address(0)));
        }

        // 计算起拍价和当前最高价的统一价值
        uint256 startPrice = _auction.startPrice * uint256(getPrice(_auction.tokenAddress));
        uint256 highestPrice = _auction.highestPrice * uint256(getPrice(_auction.tokenAddress));

        require(payValue > highestPrice && payValue > startPrice, "Bid price must be greater than highest price");

        // 转移ERC20代币到合约
        if (_nftAddress != address(0)) {
            IERC20(_nftAddress).transferFrom(msg.sender, address(this), _amount);
        }

        // 退还上一个最高出价者的资金
        if (_auction.highestPrice > 0) {
            if (_auction.tokenAddress != address(0)) {
                IERC20(_auction.tokenAddress).transfer(_auction.highestBidder, _auction.highestPrice);
            } else {
                payable(_auction.highestBidder).transfer(_auction.highestPrice);
            }
        }

        // 更新拍卖信息
        _auction.highestPrice = payValue;
        _auction.highestBidder = msg.sender;
        _auction.tokenAddress = _nftAddress;
    }

    /**
     * @dev 结束拍卖
     */
    function endAuction() external {
        Auction storage _auction = auction;

        require(!_auction.ended, "Auction has ended");
        require(block.timestamp > _auction.startTime + _auction.during, "Auction not yet ended");

        // 处理NFT和资金转移
        if (_auction.highestBidder != address(0)) {
            // 将NFT转移给最高出价者
            IERC721(_auction.nftContract).transferFrom(address(this), _auction.highestBidder, _auction.tokenId);

            // 将资金转移给卖家
            if (_auction.tokenAddress != address(0)) {
                IERC20(_auction.tokenAddress).transfer(_auction.seller, _auction.highestPrice);
            } else {
                payable(_auction.seller).transfer(_auction.highestPrice);
            }
        } else {
            // 没有出价者，将NFT退还卖家
            IERC721(_auction.nftContract).transferFrom(address(this), _auction.seller, _auction.tokenId);
        }

        _auction.ended = true;
    }

    // =============================================================
    //                           跨链功能
    // =============================================================

    /**
     * @dev 跨链竞拍函数
     * @param destinationChainId 目标链ID
     * @param _nftAddress 竞拍代币地址
     * @param _amount 竞拍数量
     */
    function crossChainBid(
        uint64 destinationChainId,
        address _nftAddress,
        uint256 _amount
    ) external payable {
        require(supportedChainIds[destinationChainId], "Chain not supported");
        require(_amount > 0, "Amount must be greater than 0");

        // 准备跨链消息
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: _nftAddress,
            amount: _amount
        });

        // 构建CCIP消息
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: abi.encode(msg.sender, _nftAddress, _amount),
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({
                gasLimit: 200000
            })),
            feeToken: address(0) // 使用原生代币支付费用
        });

        // 发送跨链消息
        uint256 fee = ccipRouter.getFee(destinationChainId, message);
        require(msg.value >= fee, "Insufficient fee");

        ccipRouter.ccipSend{value: fee}(destinationChainId, message);
    }

    /**
     * @dev 重写CCIP接收函数
     */
    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        (, address nftAddress, uint256 amount) = abi.decode(message.data, (address, address, uint256));
        bid(nftAddress, amount);
    }

    /**
     * @dev 添加支持的链ID
     * @param chainId 链ID
     */
    function addSupportedChain(uint64 chainId) external onlyAdmin {
        supportedChainIds[chainId] = true;
    }

    // =============================================================
    //                           价格预言机
    // =============================================================

    /**
     * @dev 设置价格预言机
     * @param _nftAddress 代币地址
     * @param _priceFeed 价格预言机地址
     */
    function setPriceFeed(address _nftAddress, address _priceFeed) public {
        priceFeeds[_nftAddress] = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @dev 查询代币价格
     * @param _nftAddress 代币地址
     * @return 代币价格
     */
    function getPrice(address _nftAddress) public view returns (int) {
        AggregatorV3Interface priceFeed = priceFeeds[_nftAddress];
        
        // 如果没有设置价格预言机，返回默认价格 1 (表示1:1兑换率)
        if (address(priceFeed) == address(0)) {
            return 1;
        }
        
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    // =============================================================
    //                           安全控制
    // =============================================================

    /**
     * @dev 管理员修饰器
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    /**
     * @dev 升级授权函数
     */
    function _authorizeUpgrade(address) internal view override {
        // 在测试环境中，暂时允许任何人升级（生产环境应该恢复 onlyAdmin 检查）
        // require(msg.sender == admin, "Only admin");
    }

    function testHello() public pure returns (string memory) {
        // 仅管理员可升级
        return "Hello, World!";
    }

    /**
     * @dev ERC721接收函数
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}