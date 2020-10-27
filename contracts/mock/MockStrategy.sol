// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../swap/SafeSmartSwapAbstract.sol";
import "./StrategyCurveYVoterProxyAbstract.sol";
/*
 * MockStrategy 
 */

contract MockStrategy is SafeSmartSwap, StrategyCurveYVoterProxy {
    using SafeMath for uint256;

    constructor(
        address _governanceSwap,
        address _controller
    ) public SafeSmartSwap(_governanceSwap) StrategyCurveYVoterProxy(_controller) {
        
    }

    function customHarvest(address _dex, bytes memory _data) public {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        // VoterProxy(proxy).harvest(gauge); // Deposit crv directly into strat
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            uint256 _keepCRV = _crv.mul(keepCRV).div(keepCRVMax);
            IERC20(crv).safeTransfer(voter, _keepCRV);
            _crv = _crv.sub(_keepCRV);

            // Using SafeSmartSwap to move _crv (crv) to x (dai)
            _swap(_crv, crv, dai, _dex, _data);

            // IERC20(crv).safeApprove(uni, 0);
            // IERC20(crv).safeApprove(uni, _crv);

            // address[] memory path = new address[](3);
            // path[0] = crv;
            // path[1] = weth;
            // path[2] = dai;

            // Uni(uni).swapExactTokensForTokens(_crv, uint256(0), path, address(this), now.add(1800));
        }
        uint256 _dai = IERC20(dai).balanceOf(address(this));
        if (_dai > 0) {
            IERC20(dai).safeApprove(ydai, _dai);
            yERC20(ydai).deposit(_dai);
        }
        uint256 _ydai = IERC20(ydai).balanceOf(address(this));
        if (_ydai > 0) {
            IERC20(ydai).safeApprove(curve, _ydai);
            ICurveFi(curve).add_liquidity([_ydai, 0, 0, 0], 0);
        }
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            uint256 _fee = _want.mul(performanceFee).div(performanceMax);
            IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
            deposit();
        }
        VoterProxy(proxy).lock();
    }


    function swap(uint256 _amount, address _in, address _out) internal returns (uint _amountOut) {

    }

    function swap(uint256 _amount, address _in, address _out, address _dex, bytes memory _data) internal returns (uint _amountOut) {
        
    }
}