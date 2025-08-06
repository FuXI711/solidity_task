//// SPDX-License-Identifier: MIT
pragma solidity ~0.8.0;

contract ERC20 {
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval (address indexed owner, address indexed spender, uint256 value);
    //查询余额
    function balanceOf(address addr) external view returns (uint256) {
        return _balances[addr];
    }
    //转账
     function withDrawTransfer(address from,address to, uint256 amount) public returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        require(_balances[from] >= amount, "ERC20: not enough balance");

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
     }
    //授权
     function withDrawApprove(address addr, uint256 amount)external{
        allowance[msg.sender][addr] = amount;
        emit Approval(msg.sender, addr, amount);
     }

     // 代扣（需授权）
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowance[from][msg.sender] >= amount, "ERC20: insufficient allowance");
        require(_balances[from] >= amount, "ERC20: insufficient balance");

        allowance[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

      function mint(address addr, uint256 amount) public {
        _balances[addr] += amount;
        emit Transfer(address(0), addr, amount);
      }
}