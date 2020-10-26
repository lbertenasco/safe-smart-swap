// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../../interfaces/ISafeSmartSwap.sol";
import "../../interfaces/IGovernanceSwap.sol";
import "../../interfaces/IUniswapV2Router.sol";

/*
 * SafeSmartSwap 
 */
abstract
contract SafeSmartSwap is ISafeSmartSwap {
    using SafeMath for uint256;

    IGovernanceSwap public governanceSwap;

    constructor(address _governanceSwap) public {
        governanceSwap = IGovernanceSwap(_governanceSwap);
    }


    /*
        Functions:

        - harvest(_path)

        - swap [overload]
            // default (governance) swap
            - swap(_amount, _in, _out);
            - swap(_amount, _in, _out, _min);
            - swap(_amount, _in, _out, _min, _to);
            // Custom swap
            - swap(_amount, _in, _out, data);
            - swap(_amount, _in, _out, data, _min);
            - swap(_amount, _in, _out, data, _min, _to);
     */

    function swap(uint256 _amount, address _in, address _out) external returns (uint[] memory _amounts) {
        return swap(_amount, _in, _out, uint256(0)); // default _min = 0
    }
    function swap(uint256 _amount, address _in, address _out, uint256 _min) external returns (uint[] memory _amounts) {
        return swap(_amount, _in, _out, _min, msg.sender); // default _to = msg.sender
    }

    // Governance path swap
    function swap(uint256 _amount, address _in, address _out, uint256 _min, address _to) external returns (uint[] memory _amounts) {

        address _handler = governanceSwap.getPairDefaultDexHandler(_in, _out);
        bytes memory _data = governanceSwap.getPairDefaultData(_in, _out);
        IDexHandler(_handler).swap(_data);

        return _swapExactTokensForTokens(
            _amount,
            _min,
            _to,
            _expire
        );
    }

    // Custom path swap
    function swap(uint256 _amount, address _in, address _out, uint256 _min, address _to, uint256 _expire, address[] calldata _path) external returns (uint[] memory _amounts) {
        require(_path.length > 1, 'path-length-should-be-greater-than-1');
        require(_path[0] == _in , 'path-first-token-should-be-in');
        require(_path[_path.length.sub(1)] == _out , 'path-last-token-should-be-out');

        uint256 inBalancePreSwap = IERC20(_in).balanceOf(address(this));
        uint256 outBalancePreSwap = IERC20(_out).balanceOf(address(this));

        // Get governanceSwap path for token pair
        address[] memory _governancePath = governanceSwap.getPath(_in, _out);
        uint256[] memory _governanceAmounts = uniswapV2Router.getAmountsOut(_amount, _governancePath);

        _amounts = _swapExactTokensForTokens(_amount, _min, _path, _to, _expire);

        require(
            _amounts[_amounts.length.sub(1)] >= _governanceAmounts[_governanceAmounts.length.sub(1)],
            'custom-path-is-suboptimal'
        );

        uint256 inBalancePostSwap = IERC20(_in).balanceOf(address(this));
        uint256 outBalancePostSwap = IERC20(_out).balanceOf(address(this));

        // Extra checks to avoid custom path exploits
        require(inBalancePostSwap >= inBalancePreSwap.sub(_amount), 'in-balance-mismatch');
        require(outBalancePostSwap >= outBalancePreSwap.add(_governanceAmounts[_governanceAmounts.length.sub(1)]), 'out-balance-mismatch');
    }

    function _swapExactTokensForTokens(uint256 _amount, uint256 _min, address[] calldata _path, address _to, uint256 _expire) internal returns (uint[] memory _amounts) {
        return uniswapV2Router.swapExactTokensForTokens(
            _amount,
            _min,
            _path,
            _to,
            _expire
        );
    }
}
