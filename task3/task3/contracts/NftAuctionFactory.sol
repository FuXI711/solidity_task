// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./TestNftAuction.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NftAuctionFactory is ERC721, ERC721URIStorage, Ownable {
    // 存储所有创建的拍卖合约地址
    TestNftAuction[] public auctions;
    // 跟踪地址是否为拍卖合约
    mapping(address => bool) public isAuctionContract;
    // 管理员地址
    address public admin;
    // 下一个NFT的tokenId
    uint256 private _nextTokenId;
    // 拍卖合约实现地址（用于创建代理）
    address public auctionImplementation;

    /**
     * @dev 铸造新的NFT
     * @param to 接收NFT的地址
     * @param uri NFT的元数据URI
     * @return 铸造的NFT的tokenId
     */
    function mintNFT(address to, string memory uri) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    // 添加CCIP路由地址
    address public ccipRouter;

    // 修改构造函数
    constructor(address _ccipRouter, address _auctionImplementation) ERC721("AuctionNFT", "ANFT") Ownable(msg.sender) {
        admin = msg.sender;
        _nextTokenId = 1;
        ccipRouter = _ccipRouter;
        auctionImplementation = _auctionImplementation;
    }

    /**
     * @dev 创建新的拍卖合约（使用现有NFT）
     * @param _nftAddress NFT合约地址
     * @param _tokenId NFT的tokenId
     * @param _during 拍卖持续时间
     * @param _startPrice 起拍价格
     * @return 新创建的拍卖合约地址
     */
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _during,
        uint256 _startPrice
    ) external returns (address) {
        // 只有管理员可以创建拍卖
        require(msg.sender == admin, "Only admin can create auctions");
        // 验证参数
        require(_startPrice > 0, "startPrice must be greater than 0");
        require(_during > 10, "during must be greater than 10");

        // 使用 ERC1967Proxy 创建可升级代理合约
        bytes memory initData = abi.encodeWithSelector(
            TestNftAuction.initialize.selector,
            admin,  // 使用工厂的admin（deployer）而不是工厂合约本身
            ccipRouter
        );
        ERC1967Proxy proxy = new ERC1967Proxy(auctionImplementation, initData);
        TestNftAuction newAuction = TestNftAuction(address(proxy));

        // 设置拍卖参数
        newAuction.setAuctionParameters(_nftAddress, _tokenId, _during, _startPrice);

        // 转移NFT到新拍卖合约
        IERC721(_nftAddress).transferFrom(msg.sender, address(newAuction), _tokenId);

        // 开始拍卖
        newAuction.startAuction();

        // 记录新创建的拍卖合约
        auctions.push(newAuction);
        isAuctionContract[address(newAuction)] = true;

        return address(newAuction);
    }

    // /**
    //  * @dev 创建新的拍卖合约并铸造新NFT
    //  * @param uri NFT的元数据URI
    //  * @param _during 拍卖持续时间
    //  * @param _startPrice 起拍价格
    //  * @return 新创建的拍卖合约地址和铸造的NFT的tokenId
    //  */
    // function createAuctionWithNewNFT(
    //     string memory uri,
    //     uint256 _during,
    //     uint256 _startPrice
    // ) external returns (address, uint256) {
    //     // 只有管理员可以创建拍卖
    //     require(msg.sender == admin, "Only admin can create auctions");
    //     // 验证参数
    //     require(_startPrice > 0, "startPrice must be greater than 0");
    //     require(_during > 10, "during must be greater than 10");

    //     // 铸造新NFT
    //     uint256 tokenId = mintNFT(address(this), uri);

    //     // 使用 ERC1967Proxy 创建可升级代理合约
    //     bytes memory initData = abi.encodeWithSelector(
    //         TestNftAuction.initialize.selector,
    //         admin,  // 使用工厂的admin（deployer）而不是工厂合约本身
    //         ccipRouter
    //     );
    //     ERC1967Proxy proxy = new ERC1967Proxy(auctionImplementation, initData);
    //     TestNftAuction newAuction = TestNftAuction(address(proxy));

    //     // 设置拍卖参数
    //     newAuction.setAuctionParameters(address(this), tokenId, _during, _startPrice);

    //     // 转移NFT到新拍卖合约
    //     IERC721(address(this)).transferFrom(address(this), address(newAuction), tokenId);

    //     // 开始拍卖
    //     newAuction.startAuction();

    //     // 记录新创建的拍卖合约
    //     auctions.push(newAuction);
    //     isAuctionContract[address(newAuction)] = true;

    //     return (address(newAuction), tokenId);
    // }

    // 获取所有拍卖合约
    function getAllAuctions() external view returns (TestNftAuction[] memory) {
        return auctions;
    }

    // 获取拍卖合约数量
    function getAuctionCount() external view returns (uint256) {
        return auctions.length;
    }

    // 重写必须实现的函数
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev ERC721接收函数，允许工厂合约接收NFT
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}