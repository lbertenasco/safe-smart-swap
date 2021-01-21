// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import "./DexHandlerAbstract.sol";
import "../../interfaces/dex/IUniswapV2Router.sol";
import "../../interfaces/dex-handlers/IDefaultHandler.sol";
/*
 * Default Handler 
 * TODO:
 * - add curve (check for pools, see yearn-treasury)
 * - 
 */

contract DefaultHandler is DexHandler, IDefaultHandler { // TODO Add dust collection
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IUniswapV2Router public uniswapV2Router;

    constructor(address _uniswapV2Router) DexHandler(_uniswapV2Router) public {
        uniswapV2Router = IUniswapV2Router(_uniswapV2Router);
    }

    function getPairDefaultDex(address _in, address _out) external view override returns(address _dex) {
        return address(uniswapV2Router);
    }

    function getPairDefaultData(address _in, address _out) external view override returns(bytes memory _data) {
        return customSwapData(_in, _out);
    }


    function swap(bytes memory _data, uint256 _amount) public override returns (uint256 _amountOut) {
        return customSwap(_data, _amount);
    }

    function customSwap(bytes memory _data, uint256 _amount) public returns (uint256 _amountOut) {
        (address _in, address _out) = customDecodeData(_data);
        // Transfer _in tokens to self
        IERC20(_in).safeTransferFrom(msg.sender, address(this), _amount);

        // IERC20(_in).approve(address(uniswapV2Router), 0); // Not needed if allowance always goes back to 0
        IERC20(_in).approve(address(uniswapV2Router), _amount);
        

        uint[] memory _amounts = uniswapV2Router.swapExactTokensForTokens(
            _amount,
            0,
            getPath(_in, _out),
            msg.sender,
            now.add(1 hours)
        );

        return _amounts[_amounts.length.sub(1)];
    }

    function getAmountOut(bytes memory _data, uint256 _amount) public override view returns (uint256 _amountOut) {
        (address _in, address _out) = customDecodeData(_data);

        uint256[] memory _amounts = uniswapV2Router.getAmountsOut(_amount, getPath(_in, _out));

        return _amounts[_amounts.length.sub(1)];
    }
 
    function decodeData(bytes memory _data) public override pure {
        _data; // silence warning
        require(false, 'use customDecodeData(bytes memory _data) returns (address _in, address _out)');
    }
    function customDecodeData(bytes memory _data) public pure returns (address _in, address _out) {
        return abi.decode(_data, (address, address));
    }

    function swapData() external override pure returns (bytes memory) {
        require(false, 'use customSwapData(address _in, address _out) external pure returns (bytes memory);');
    }
    function customSwapData(
        address _in,
        address _out
    ) public pure returns (bytes memory) {
        return abi.encode(
            _in,
            _out
        );
    }

    function getPath(address _in, address _out) internal pure returns (address[] memory _path) {
        if (weth == _in || weth == _out) {
            _path = new address[](2);
            _path[0] = _in;
            _path[1] = _out;
        } else {
            _path = new address[](3);
            _path[0] = _in;
            _path[1] = weth;
            _path[2] = _out;
        }
    }
}
