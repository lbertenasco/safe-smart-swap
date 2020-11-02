// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../../interfaces/IGovernanceSwap.sol";
import "../../interfaces/IDexHandler.sol";

import '../utils/Governable.sol';
import '../utils/CollectableDust.sol';

/*
 * GovernanceSwap 
 */

contract GovernanceSwap is Governable, CollectableDust, IGovernanceSwap {
    using SafeMath for uint256;

    // Dex handlers mapping
    mapping(address => address) internal dexHandlers;

    // in => out defaults
    mapping(address => mapping(address => address)) internal defaultPairDex;
    mapping(address => mapping(address => bytes)) internal defaultPairData;

    constructor() public Governable(msg.sender) CollectableDust() {
    }

    

    /*
        Governance Functions:

        - addDexHandler(_dex, _handler)
        - removeDexHandler(_dex, _handler)
        - setPairDefaults(_in, _out, _dex, _data)

     */


    function addDexHandler(address _dex, address _handler) external override onlyGovernor returns (bool) {
        require(dexHandlers[_dex] == address(0), 'governance-swap::add-dex:dex-already-exists');
        require(IDexHandler(_handler).isDexHandler(), 'governance-swap::add-dex:contract-is-not-handler');
        dexHandlers[_dex] = _handler;
        return true;
    }

    function removeDexHandler(address _dex) external override onlyGovernor returns (bool) {
        require(dexHandlers[_dex] != address(0), 'governance-swap::add-dex:dex-does-not-exists');
        dexHandlers[_dex] = address(0);
        return true;
    }

    function setPairDefaults(address _in, address _out, address _dex, bytes memory _data) public override onlyGovernor returns (bool) {
        require(dexHandlers[_dex] != address(0), 'governance-swap::set-pair-defaults:dex-does-not-have-handler');
        require(_in != _out, 'governance-swap::set-pair-defaults:in-equals-out');
        defaultPairDex[_in][_out] = _dex;
        defaultPairData[_in][_out] = _data;
        return true;
    }



    /*
        Getter Functions:

        - getPairDefaultDex(_in, _out) returns (address _dex)
        - getPairDefaultDexHandler(_in, _out) returns (address _handler)
        - getDexHandler(_dex) returns (address _handler)
        - getPairDefaultData(_in, _out) returns (bytes memory _data)
            
        -     

     */
    function getPairDefaultDex(address _in, address _out) external override returns (address _dex) {
        return defaultPairDex[_in][_out];
    }
    function getPairDefaultDexHandler(address _in, address _out) external override returns (address _handler) {
        return dexHandlers[defaultPairDex[_in][_out]];
    }
    function getDexHandler(address _dex) external override returns (address _handler) {
        return dexHandlers[_dex];
    }
    function getPairDefaultData(address _in, address _out) external override returns (bytes memory _data) {
        return defaultPairData[_in][_out];
    }


    // Governable
    function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
        _setPendingGovernor(_pendingGovernor);
    }

    function acceptGovernor() external override onlyPendingGovernor {
        _acceptGovernor();
    }

    // Collectable Dust
    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external override onlyGovernor {
        _sendDust(_to, _token, _amount);
    }
    
}
