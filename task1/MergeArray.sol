// SPDX-License-Identifier: MIT
pragma solidity ~0.8.0;

contract MergeSorted {
    /**
     * @dev 合并两个已排序的数组
     * @param a 第一个已排序数组
     * @param b 第二个已排序数组
     * @return 合并后的已排序数组
     */
    function merge(int[] memory a, int[] memory b) public pure returns (int[] memory) {
        uint i = 0;
        uint j = 0;
        uint k = 0;
        uint aLen = a.length;
        uint bLen = b.length;
        
        int[] memory result = new int[](aLen + bLen);
        
        while (i < aLen && j < bLen) {
            if (a[i] <= b[j]) {
                result[k] = a[i];
                i++;
            } else {
                result[k] = b[j];
                j++;
            }
            k++;
        }
        
        // 处理一下剩余元素
        while (i < aLen) {
            result[k] = a[i];
            i++;
            k++;
        }
        
        while (j < bLen) {
            result[k] = b[j];
            j++;
            k++;
        }
        
        return result;
    }
}
