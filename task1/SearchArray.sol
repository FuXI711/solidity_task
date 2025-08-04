// SPDX-License-Identifier: MIT
pragma solidity ~0.8.0;

contract SearchArray {
    /**
     * @dev 合并两个已排序的数组
     */
    function search(int[] memory arr, int target) public pure returns (int) {
        uint left = 0;
        uint right = arr.length;
        while (left < right) { 
            uint mid = left + (right - left) / 2; 
            
            if (arr[mid] == target) {
                return int(mid);
            } else if (arr[mid] < target) {
                left = mid + 1; 
            } else {
                right = mid;
            }
        }
        
        return -1; // 未找到
    }
}
