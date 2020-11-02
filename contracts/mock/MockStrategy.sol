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

    function customHarvest(address _dex, bytes memory _data) public returns (uint256 _amountOut) {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        // VoterProxy(proxy).harvest(gauge); // Deposit crv directly into strat
        uint256 _amount = IERC20(crv).balanceOf(address(this));
        if (_amount > 0) {
            // uint256 _keepCRV = _amount.mul(keepCRV).div(keepCRVMax);
            // IERC20(crv).safeTransfer(voter, _keepCRV);
            // _amount = _amount.sub(_keepCRV);

            // Using SafeSmartSwap to move _amount (crv) to x (dai) via custom dex-data
            _swap(_amount, crv, dai, _dex, _data);
            // Replaces this code below:

            // IERC20(crv).safeApprove(uni, 0);
            // IERC20(crv).safeApprove(uni, _amount);

            // address[] memory path = new address[](3);
            // path[0] = crv;
            // path[1] = weth;
            // path[2] = dai;

            // Uni(uni).swapExactTokensForTokens(_amount, uint256(0), path, address(this), now.add(1800));
        }
        uint256 _dai = IERC20(dai).balanceOf(address(this));
        return _dai;
    }

    function harvest() public override {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
        
            // Using SafeSmartSwap to move _crv (crv) to x (dai) via default governance dex-data
            _swap(_crv, crv, dai);
            // Replaces this code below:

            // IERC20(crv).safeApprove(uni, 0);
            // IERC20(crv).safeApprove(uni, _crv);

            // address[] memory path = new address[](3);
            // path[0] = crv;
            // path[1] = weth;
            // path[2] = dai;

            // Uni(uni).swapExactTokensForTokens(_crv, uint256(0), path, address(this), now.add(1800));
        }
    }

    function oldHarvest() public {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
        
            // Replaces this code below:

            IERC20(crv).safeApprove(uni, 0);
            IERC20(crv).safeApprove(uni, _crv);

            address[] memory path = new address[](3);
            path[0] = crv;
            path[1] = weth;
            path[2] = dai;

            Uni(uni).swapExactTokensForTokens(_crv, uint256(0), path, address(this), now.add(1800));
        }
    }

}