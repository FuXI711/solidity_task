// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IntegerToRoman {
    function intToRoman(uint256 num) public pure returns (string memory) {
        require(num >= 1 && num <= 3999, "Only numbers 1-3999 are supported");
        
        string[13] memory romanSymbols = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];
                
        uint256[13] memory values = [uint256(1000), uint256(900), uint256(500), uint256(400), 
                                    uint256(100), uint256(90), uint256(50), uint256(40), 
                                    uint256(10), uint256(9), uint256(5), uint256(4), uint256(1)];

        bytes memory result;
        
        for (uint256 i = 0; i < romanSymbols.length; i++) {
            while (num >= values[i]) {
                result = abi.encodePacked(result, romanSymbols[i]);
                num -= values[i];
            }
        }
        return string(result);
    }
}
