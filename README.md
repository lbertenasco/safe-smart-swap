# CustomSwaps (Governance Safe Smart Swaps)
> name is not final, all suggestions are welcome

[![docs](https://img.shields.io/badge/docs-%F0%9F%93%84-blue)](https://lbertenasco.gitbook.io/custom-swaps/)

These contracts were developed to allow devs to provide a safe, flexible and governable way to handle swaps on their smart contracts.
This has synergy with [keep3r.network](http://keep3r.network/) since keep3rs can submit custom dex+data to reduce slippage (and possibly get a bonus for it)

## Wishlist

### DexHandlers

* [x] [`Uniswap`](./contracts/dex-handlers/UniswapV2DexHandler.sol) (`swapExactTokensForTokens`)
* [x] [`Sushiswap`](./contracts/dex-handlers/UniswapV2DexHandler.sol) (`swapExactTokensForTokens`)
* [ ] 0x
* [ ] bancor
* [ ] paraswap
* [ ] crv
* [ ] 1inch

### Integrations

* [ ] yearn strategy
* [ ] erc20-dca (TBD)

## Run tests

- `npm i`
- `cp example.config.json .config.json`
    - add Infura and Alchemy APIs
    - add "accounts.mainnet.publicKey" (should have ETH balance > 3 for tests to run ok)
- `npm test`
    - use `npm run test:gas` to get gas report


## Contracts

---
> dex-handlers


### [`DexHandlerAbstract.sol`](./contracts/dex-handlers/DexHandlerAbstract.sol)

Abstract contract that should be used to extend from when creating DexHandlers. (see [`UniswapV2DexHandler.sol`](./contracts/dex-handlers/UniswapV2DexHandler.sol))

```sol
address public dex;
constructor(address _dex) public {
    require(_dex.isContract(), 'dex-handler::constructor:dex-is-not-a-contract');
    dex = _dex;
}
function isDexHandler() external override view returns (bool) { return true; }
function swap(bytes memory _data, uint256 _amount) public virtual override returns (uint256 _amountOut) {}
function getAmountOut(bytes memory _data, uint256 _amount) public virtual override view returns (uint256 _amountOut) {}
function swapData() external virtual override pure returns (bytes memory) {}
function decodeData(bytes memory _data) public virtual pure;
```


### [`UniswapV2DexHandler.sol`](./contracts/dex-handlers/UniswapV2DexHandler.sol)
> [uniswap verified on etherscan](https://etherscan.io/address/0x293aC14CB38E2443d9c95C185A25b8EA6f2f18A2#code)

> [sushiswap verified on etherscan](https://etherscan.io/address/0xfB5Ab2909A455934214A7b84C802fbFBcE7c4e9F#code)

UniswapV2 custom DexHandler.

Overrides following DexHandlerAbstract functions:
```sol
function swap(bytes memory _data, uint256 _amount) public override returns (uint256 _amountOut)
function getAmountOut(bytes memory _data, uint256 _amount) public override view returns (uint256 _amountOut)
function decodeData(bytes memory _data) public override pure
function swapData() external override pure returns (bytes memory) {
```

For `decodeData` it always returns a message pointing to correct custom implementation:
```sol
require(false, 'use customDecodeData(bytes memory _data) returns (uint256 _amount, uint256 _min, address[] memory _path, address _to, uint256 _expire)');
```

For `swapData` it always returns a message pointing to correct custom implementation:
```sol
require(false, 'use customSwapData(uint256 _amount, uint256 _min, address[] memory _path, address _to, uint256 _expire) returns (bytes memory)');
```

> These 2 functions above will return a different message for other DexHandlers (more examples in the future)

`customSwap` handles decoding and overwriting the data + the UniswapV2 logic for `swapExactTokensForTokens`


---
> swap


### [`GovernanceSwap.sol`](./contracts/swap/GovernanceSwap.sol)
> [verified on etherscan](https://etherscan.io/address/0x220c33Bb71D3b6A6a6EA2036AbDb1C9449447afc#code)

Governance managed mappings for dex and pairs.
```sol
// Dex handlers mapping
mapping(address => address) internal dexHandlers;
// in => out defaults
mapping(address => mapping(address => address)) internal defaultPairDex;
mapping(address => mapping(address => bytes)) internal defaultPairData;
```

This contract and it's governance need to be REALLY secure and trustworthy, since they have the ability to steal funds and/or block custom swaps by introducing an evil handler and/or data into a pair's default.
> I need to find a way to incentivize good behaviour and minimize oversight required.


### [`SafeSmartSwapAbstract.sol`](./contracts/swap/SafeSmartSwapAbstract.sol)

Abstract contract that has all the internal functions to safely handle and verify swaps done via GovernanceSwap + DexHandlers.

Contracts that extend `SafeSmartSwap` should call `SafeSmartSwap(_governanceSwap)` on construction. (see [`MockStrategy.sol`](./contracts/mock/MockStrategy.sol))

There are only 2 functions that respectively handle default and custom swaps:
```sol
// Governance swap
function _swap(uint256 _amount, address _in, address _out) internal returns (uint _amountOut)
// Custom swap
function _swap(uint256 _amount, address _in, address _out, address _dex, bytes memory _data) internal returns (uint _amountOut)
```

Governance (default) swaps spend less gas since they don't require extra checks (see gas spendage with `npm run test:gas`)

Custom swaps reverts if the output is less than the estimated output by the current Governance (default) swap for the pair.
```sol
require(_amountOut >= _governanceAmountOut, 'custom-swap-is-suboptimal');
```

Also checks final token balances in case the dex+data used was maliciously returning a higher `_amountOut`:
```sol
require(inBalancePostSwap >= inBalancePreSwap.sub(_amount), 'in-balance-mismatch');
require(outBalancePostSwap >= outBalancePreSwap.add(_governanceAmountOut), 'out-balance-mismatch');
```


---
> mock


### [`MockStrategy.sol`](./contracts/mock/MockStrategy.sol)

Mocked Strategy based on yearn's [`StrategyCurveYVoterProxy.sol`](./contracts/mock/StrategyCurveYVoterProxyAbstract.sol)

Extends [`SafeSmartSwapAbstract.sol`](./contracts/swap/SafeSmartSwapAbstract.sol), constructor needs `address _governanceSwap`.

3 key/test functions are:
```sol
// Swaps CRV to DAI by using a custom dex (available on GovernanceSwap) + custom data (can be created by using dex default handler)
function customHarvest(address _dex, bytes memory _data) public returns (uint256 _amountOut)
// New harvest function that uses GovernanceSwap default dex and data
function harvest() public override
// Legacy harvest function that uses uniswap and hardcoded path
function oldHarvest() public
```
