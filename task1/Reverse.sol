pragma solidity ^0.8.0;

contract Reverse {


    function reverseString(string memory input) public pure returns (string memory) {
        bytes memory strBytes = bytes(input);//string 转byte
        uint256 length = strBytes.length;
        
        bytes memory reversed = new bytes(length);//创建新的byte接受反转数据
        
        for (uint256 i = 0; i < length; i++) {
            reversed[i] = strBytes[length - 1 - i];
        }
        
        return string(reversed);
    }
}
