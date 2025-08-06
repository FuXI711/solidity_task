// SPDX-License-Identifier: MIT
pragma solidity ~0.8.0;

contract Donation{

    mapping(address => uint256) public donations;//捐款金额
    mapping(address => bool) public donated;//是否捐款
    uint256 public totalDonations;//总捐款金额
    uint256 public totalDonors;//捐款人数量 

    constructor(){
        payable(msg.sender).transfer(address(this).balance);
    }

//
    function donate() public payable{
        require(!donated[msg.sender], "You have already donated");
        donations[msg.sender] = msg.value;
        donated[msg.sender] = true;
        totalDonations += msg.value;
        totalDonors++;
    }
//提取
    function withdraw() public{
        payable(msg.sender).transfer(address(this).balance);
    }

//
    function getDonation(address _donor) public view returns (uint256){
        return donations[_donor];
    }

    function getBlance() public view returns (uint256){
        return address(this).balance;
    }
}
