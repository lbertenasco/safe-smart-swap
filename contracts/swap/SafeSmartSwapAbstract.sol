// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import "../../interfaces/dex-handlers/IDexHandler.sol";
import "../../interfaces/governance-swap/IGovernanceSwap.sol";

/*
 * SafeSmartSwapAbstract
 */
abstract
contract SafeSmartSwap {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IGovernanceSwap public governanceSwap;

    bool public governanceSwapStrict = true;

    constructor(address _governanceSwap) public {
        _setGovernanceSwap(_governanceSwap);
    }

    // Setter
    function _setGovernanceSwap(address _governanceSwap) internal {
        require(IGovernanceSwap(_governanceSwap).isGovernanceSwap(), 'safe-smart-swap::set-governance-swap:is-not-governance-swap');
        governanceSwap = IGovernanceSwap(_governanceSwap);
    }
    function _setGovernanceSwapStrict(bool _strict) internal {
        require(governanceSwapStrict != _strict, 'safe-smart-swap::set-governance-swap:strict:no-change');
        governanceSwapStrict = _strict;
    }

    function _getAmountOut(uint256 _amount, address _in, address _out) internal view returns (uint256 _amountOut) {
        address _defaultHandler = governanceSwap.getPairDefaultDexHandler(_in, _out, governanceSwapStrict);
        bytes memory _defaultData = governanceSwap.getPairDefaultData(_in, _out, governanceSwapStrict);
        return IDexHandler(_defaultHandler).getAmountOut(_defaultData, _amount);
    }

    function _getAmountOut(uint256 _amount, address _dex, bytes memory _data) internal view returns (uint256 _amountOut) {
        address _handler = governanceSwap.getDexHandler(_dex, governanceSwapStrict);
        return IDexHandler(_handler).getAmountOut(_data, _amount);
    }

    // Governance swap
    function _swap(uint256 _amount, address _in, address _out) internal returns (uint256 _amountOut) {

        address _handler = governanceSwap.getPairDefaultDexHandler(_in, _out, governanceSwapStrict);
        require(_handler != address(0), 'no-default-handler');
        bytes memory _data = governanceSwap.getPairDefaultData(_in, _out, governanceSwapStrict);

        IERC20(_in).approve(_handler, _amount);
        _amountOut = IDexHandler(_handler).swap(_data, _amount);
    }

    // Custom swap
    function _swap(uint256 _amount, address _in, address _out, address _dex, bytes memory _data) internal returns (uint256 _amountOut, uint256 _defaultOut) {
        // Use default swap if no custom dex and data was used
        require(_dex != address(0), 'no-dex');

        uint256 inBalancePreSwap = IERC20(_in).balanceOf(address(this));
        uint256 outBalancePreSwap = IERC20(_out).balanceOf(address(this));

        // Get governanceSwap amount for token pair
        address _defaultHandler = governanceSwap.getPairDefaultDexHandler(_in, _out, governanceSwapStrict);
        bytes memory _defaultData = governanceSwap.getPairDefaultData(_in, _out, governanceSwapStrict);
        _defaultOut = IDexHandler(_defaultHandler).getAmountOut(_defaultData, _amount);

        address _handler = governanceSwap.getDexHandler(_dex, governanceSwapStrict);
        require(_handler != address(0), 'no-handler-for-dex');
        
        IERC20(_in).approve(_handler, _amount);
        _amountOut = IDexHandler(_handler).swap(_data, _amount);

        require(_amountOut >= _defaultOut, 'custom-swap-is-suboptimal');
        // TODO Check gas spendage if _amountOut == _defaultOut to avoid gas mining? (overkill) [need this check for keep3r ]

        uint256 inBalancePostSwap = IERC20(_in).balanceOf(address(this));
        uint256 outBalancePostSwap = IERC20(_out).balanceOf(address(this));

        // Extra checks to avoid custom dex+data exploits
        require(inBalancePostSwap >= inBalancePreSwap.sub(_amount), 'in-balance-mismatch');
        require(outBalancePostSwap >= outBalancePreSwap.add(_defaultOut), 'out-balance-mismatch');
    }

}
