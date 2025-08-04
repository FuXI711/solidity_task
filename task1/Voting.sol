
// SPDX-License-Identifier: MIT
pragma solidity ~0.8.0;

contract Voting{

    mapping ( address => uint256) public votesReceived;
    address[] public candidates;

    function vote( address addr ) public {
        if(votesReceived[addr] == 0){
            candidates.push(addr);
        }
        uint256 count = votesReceived[addr];
       count++;
       votesReceived[addr] = count;
    }
    function getUserBalance(address user) public view returns (uint256) {
        return votesReceived[user];
    }

    function resetVotes() public {
        for (uint i = 0; i < candidates.length; i++) {
            votesReceived[candidates[i]] = 0;
        }
    }
}
