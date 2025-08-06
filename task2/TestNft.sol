// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "c:/Users/15961/init_order/solidity_task/task2/node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

//合约地址：0xa9D67c8B96C47f7ed4d65AAFA0b79De9Bda578c7
contract MyNFT is ERC721URIStorage {

    constructor() ERC721("MyNFT", "MNFT") {}

    function mintNFT(address recipient, uint256 tokenId, string memory tokenURI)
        public
        returns (uint256)
    {
        _mint(recipient, tokenId);//铸币到我的钱包地址
        _setTokenURI(tokenId, tokenURI);//铸币关联元数据
        return tokenId;
    }
}