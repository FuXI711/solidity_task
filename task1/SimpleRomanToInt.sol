// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleRomanToInt {
    function romanToInt(string memory s) public pure returns (uint256) {
        uint256 result = 0;
        uint256 prevValue = 0;
        
        for (uint256 i = bytes(s).length; i > 0; i--) {
            bytes1 currentChar = bytes(s)[i-1];
            uint256 currentValue = getValue(currentChar);
            
            if (currentValue < prevValue) {
                result -= currentValue;
            } else {
                result += currentValue;
            }
            
            prevValue = currentValue;
        }
        
        return result;
    }
    
    function getValue(bytes1 romanChar) internal pure returns (uint256) {
        if (romanChar == 'I') return 1;
        if (romanChar == 'V') return 5;
        if (romanChar == 'X') return 10;
        if (romanChar == 'L') return 50;
        if (romanChar == 'C') return 100;
        if (romanChar == 'D') return 500;
        if (romanChar == 'M') return 1000;
        revert("exception!!!");
    }
}
