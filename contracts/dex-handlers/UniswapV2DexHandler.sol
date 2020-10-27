// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./DexHandlerAbstract.sol";
import "../../interfaces/IUniswapV2Router.sol";
/*
 * UniswapV2 Handler 
 */

contract UniswapV2DexHandler is DexHandler { // TODO Add dust collection
    using SafeMath for uint256;

    IUniswapV2Router public uniswapV2Router;

    constructor(address _uniswapV2Router) DexHandler(_uniswapV2Router) public {
        uniswapV2Router = IUniswapV2Router(_uniswapV2Router);
        // TODO UniswapV2 specific contract checks
    }


    function swap(bytes memory _data) public returns (uint256 _amountOut) {
        return swap(_data, 0);
    }

    function swap(bytes memory _data, uint256 _amount) public override returns (uint256 _amountOut) {
        (, uint256 _min, address[] memory _path,,) = decodeData(_data);
        // TODO Overkill: re-encode with modified data, submit _swap on abstract with data then use decode to get values out.

        uint[] memory _amounts = uniswapV2Router.swapExactTokensForTokens(
            _amount,
            _min,
            _path,
            msg.sender,
            now.add(1 hours)
        );

        // Custom UniswapV2 result parsing to get _amountOut of swap
        // (uint256[] memory amounts) = abi.decode(_result, (uint256[])); // Not neccesarry
        return _amounts[_amounts.length - 1];
    }

    function getAmountOut(bytes memory _data, uint256 _amount) public override view returns (uint256 _amountOut) {
        (,, address[] memory _path,,) = decodeData(_data);

        uint256[] memory _amounts = uniswapV2Router.getAmountsOut(_amount, _path);

        return _amounts[_amounts.length - 1];
    }
 
    function decodeData(bytes memory _data) internal pure returns (uint256 _amount, uint256 _min, address[] memory _path, address _to, uint256 _expire) {
        return abi.decode(_data, (uint256, uint256, address[], address, uint256));
    }

    function swapData() external override pure returns (bytes memory) {
        require(false, 'use customSwapData(uint256 _amount, uint256 _min, address[] memory _path, address _to, uint256 _expire)');
    }
    function customSwapData(
        uint256 _amount,
        uint256 _min,
        address[] memory _path,
        address _to,
        uint256 _expire
    ) public pure returns (bytes memory) {
        return abi.encodeWithSignature(
            "swapExactTokensForTokens(uint,uint,address[],address,uint)",
            _amount,
            _min,
            _path,
            _to,
            _expire
        );
    }
}
