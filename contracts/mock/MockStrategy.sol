// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../swap/SafeSmartSwapAbstract.sol";
/*
 * MockStrategy 
 */

contract MockStrategy is SafeSmartSwap {
    using SafeMath for uint256;

    constructor(address _governanceSwap) public SafeSmartSwap(_governanceSwap) {
        
    }


    function swap(uint256 _amount, address _in, address _out) internal returns (uint _amountOut) {

    }

    function swap(uint256 _amount, address _in, address _out, address _dex, bytes memory _data) internal returns (uint _amountOut) {
        
    }
}