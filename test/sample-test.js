const { expect } = require('chai');
const config = require('../.config.json');

const base18DecimalUnit = ethers.BigNumber.from(1).pow(10, 18);

describe('MockStrategy', function() {
  let owner;
  let alice;
  before('Setup accounts and contracts', async () => {
    [owner, alice] = await ethers.getSigners();
  });

  it('Should deploy new MockStrategy with GovernanceSwap', async function() {
    const GovernanceSwap = await ethers.getContractFactory('GovernanceSwap');
    const governanceSwap = await GovernanceSwap.deploy();
    const MockStrategy = await ethers.getContractFactory('MockStrategy');
    const mockStrategy = await MockStrategy.deploy(governanceSwap.address, config.contracts.mainnet.controller.address);
    await mockStrategy.deployed();
    const name = await mockStrategy.getName();
    expect(name).to.equal('StrategyCurveYVoterProxy');
  });

  it.only('Should deploy on mainnet fork', async function() {
    const GovernanceSwap = await ethers.getContractFactory('GovernanceSwap');
    const governanceSwap = await GovernanceSwap.deploy();
    
    const MockStrategy = await ethers.getContractFactory('MockStrategy');
    const mockStrategy = await MockStrategy.deploy(governanceSwap.address, config.contracts.mainnet.controller.address);
    
    const uniswapV2Address = config.contracts.mainnet.uniswapV2Router.address;
    const UniswapV2DexHandler = await ethers.getContractFactory('UniswapV2DexHandler');
    const uniswapV2DexHandler = await UniswapV2DexHandler.deploy(uniswapV2Address);
    await uniswapV2DexHandler.deployed();
    
    const isDexHandler = await uniswapV2DexHandler.isDexHandler();
    expect(isDexHandler).to.be.true;
    await governanceSwap.addDexHandler(uniswapV2Address, uniswapV2DexHandler.address);


    // Add CRV -> WETH -> DAI path and data for uniswapv2
    const crvAddress = await mockStrategy.callStatic.crv();
    const daiAddress = await mockStrategy.callStatic.dai();
    const wethAddress = await mockStrategy.callStatic.weth();
    const customSwapData = await uniswapV2DexHandler.callStatic.customSwapData(
      0, // _amount
      0, // _min
      [crvAddress, wethAddress, daiAddress], // _path
      owner.address, // _to
      0// _expire
    );
    console.log({ customSwapData });
    await governanceSwap.setPairDefaults(crvAddress, daiAddress, uniswapV2Address, customSwapData);


    // Add WETH -> CRV path and data for uniswapv2
    const customSwapData2 = await uniswapV2DexHandler.callStatic.customSwapData(
      0, // _amount
      0, // _min
      [wethAddress, crvAddress], // _path
      owner.address, // _to
      0// _expire
    );
    console.log({ customSwapData2 });
    await governanceSwap.setPairDefaults(wethAddress, crvAddress, uniswapV2Address, customSwapData2);

    // Use governanceSwap to optimally swap tokens
    const handlerAddress = await governanceSwap.callStatic.getPairDefaultDexHandler(wethAddress, crvAddress);
    console.log(handlerAddress)
    const swapData = await governanceSwap.callStatic.getPairDefaultData(wethAddress, crvAddress);
    const dexHandler = await ethers.getContractAt('DexHandler', handlerAddress, owner);
    const amount = base18DecimalUnit.mul(10);
    const wethContract = await ethers.getContractAt('ERC20Token', wethAddress, owner);
    // approve
    await owner.sendTransaction({ to: wethAddress, value: amount })
    await wethContract.approve(dexHandler.address, amount);
    console.log('Fix this! issues with abstract contracts?');
    const swap = await dexHandler.swap(swapData, amount);
    

    console.log(swap)
    
  });

});
