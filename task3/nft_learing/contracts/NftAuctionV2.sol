// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ~0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";



contract NftAuctionV2 is Initializable{

    struct Auction{
        //卖家
        address seller;
        //拍卖持续时间
        uint256 duration;  
        //开始价格 
        uint256 startPrice;
        //开始时间
        uint256 startTime;
        //结束时间
        uint256 endTime;
        //是否结束
        bool ended;
        //最高出价
        address highestBidder;
        //最高价格
        uint256 highestBid;
        //NFT合约地址
        address nftContract;
        //NFT的id
        uint256 tokenId;
    }

    //拍卖列表
    mapping(uint256 => Auction) public auctions;
    //下一个拍卖id
    uint256 public nextAuctionId;

    //管理员地址
    address public admin;

    function initialize() public initializer{
        admin = msg.sender;
    }
     
    //创建拍卖
    function createAution(uint256 _duration, uint256 _startPrice,address _nftContract,uint256 _tokenId) public{

        //只有管理员才能创建拍卖
        require(msg.sender == admin, "only admin can create aution");
        //检查参数
        require(_duration > 1000 * 60, "duration must be greater than 0");
        require(_startPrice > 0, "startPrice must be greater than 0");
        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            duration: _duration,
            startPrice: _startPrice,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            ended: false,
            highestBidder: address(0),
            highestBid: 0,
            nftContract: _nftContract,
            tokenId: _tokenId

        });

        nextAuctionId++;
    }   
    //买家参与买单
    function placeBid(uint256 _autionId) public payable{
        Auction storage auction = auctions[_autionId];
        //检查是否结束
        require(!auction.ended && auction.startTime + auction.duration > block.timestamp, "aution has ended");
        //检查是否是最高价
        require(msg.value > auction.highestBid, "bid price must be greater than highest bid");
        //退回之前的最高出价者
        if(auction.highestBidder != address(0)){
            payable(auction.highestBidder).transfer(auction.highestBid);
        }
        //更新最高出价
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
    }
    //结束拍卖
    function endAution(uint256 _autionId) public{
        Auction storage auction = auctions[_autionId];
        //检查是否结束
        require(!auction.ended, "aution has ended");
        //检查是否是卖家
        require(msg.sender == auction.seller, "only seller can end aution");
        //更新状态
        auction.ended = true;
    }   

    function testHello() public pure returns(string memory){
        return "hello world";
    }

}