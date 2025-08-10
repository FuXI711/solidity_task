// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ~0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract task1 is ERC20 {

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    
    //铸币
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    //查询余额
    function balanceOf(address from) public view returns (uint256) {
        return balances(from);
    }

    


}
