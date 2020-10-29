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
    const crvContract = await ethers.getContractAt('ERC20Token', crvAddress, owner);
    const daiContract = await ethers.getContractAt('ERC20Token', daiAddress, owner);
    const wethContract = await ethers.getContractAt('ERC20Token', wethAddress, owner);

    const customSwapDataCrvDai = await uniswapV2DexHandler.callStatic.customSwapData(
      0, // _amount
      0, // _min
      [crvAddress, wethAddress, daiAddress], // _path
      owner.address, // _to
      0// _expire
    );
    await governanceSwap.setPairDefaults(crvAddress, daiAddress, uniswapV2Address, customSwapDataCrvDai);


    // Add WETH -> CRV path and data for uniswapv2
    const customSwapDataWethCrv = await uniswapV2DexHandler.callStatic.customSwapData(
      0, // _amount
      0, // _min
      [wethAddress, crvAddress], // _path
      owner.address, // _to
      0// _expire
    );
    await governanceSwap.setPairDefaults(wethAddress, crvAddress, uniswapV2Address, customSwapDataWethCrv);

    // Use governanceSwap to optimally swap tokens
    const handlerAddress = await governanceSwap.callStatic.getPairDefaultDexHandler(wethAddress, crvAddress);
    console.log(handlerAddress)
    const swapDataWethCrv = await governanceSwap.callStatic.getPairDefaultData(wethAddress, crvAddress);
    const dexHandler = await ethers.getContractAt('UniswapV2DexHandler', handlerAddress, owner);
    const amount = base18DecimalUnit.mul(10);

    // Get WETH and approve
    await owner.sendTransaction({ to: wethAddress, value: amount })
    await wethContract.approve(dexHandler.address, amount);
    
    // Validate decoded data
    const decodedSwapDataWethCrv = await dexHandler.customDecodeData(swapDataWethCrv);
    expect(decodedSwapDataWethCrv._path).to.deep.eq([wethAddress, crvAddress]);

    // Swap WETH to CRV
    await dexHandler.customSwap(swapDataWethCrv, amount);    
    const crvBalance = await crvContract.callStatic.balanceOf(owner.address);
        
    // Send CRV to strategy
    await crvContract.transfer(mockStrategy.address, crvBalance)

    const strategyCrvBalance = await crvContract.callStatic.balanceOf(mockStrategy.address);
    console.log({ strategyCrvBalance: crvBalance.toNumber() });

    // Suboptimal route in data
    const suboptimalSwapDataCrvDai = await uniswapV2DexHandler.callStatic.customSwapData(
      0, // _amount
      0, // _min
      [crvAddress, daiAddress], // _path
      owner.address, // _to
      0// _expire
    );
    // Should revert with 'custom-swap-is-suboptimal'
    await expect(mockStrategy.customHarvest(uniswapV2Address, suboptimalSwapDataCrvDai))
      .to.be.revertedWith('custom-swap-is-suboptimal');
    
    // Should succeed by sending the same path governance uses 
    await mockStrategy.customHarvest(uniswapV2Address, customSwapDataCrvDai);
    const strategyDaiBalance = await daiContract.callStatic.balanceOf(mockStrategy.address);

    console.log({ strategyDaiBalance: strategyDaiBalance.toNumber() })


    // More rewards!
    // Get WETH and approve
    await owner.sendTransaction({ to: wethAddress, value: amount })
    await wethContract.approve(dexHandler.address, amount);

    // Swap WETH to CRV
    await dexHandler.customSwap(swapDataWethCrv, amount);
    const crvBalance2 = await crvContract.callStatic.balanceOf(owner.address);

    // Send CRV to strategy
    await crvContract.transfer(mockStrategy.address, crvBalance2)

    // Default harvest
    await mockStrategy.harvest();

    const strategyDaiBalance2 = await daiContract.callStatic.balanceOf(mockStrategy.address);

    console.log({ strategyDaiBalance2: strategyDaiBalance2.toNumber() })
    

    // Even more rewards!
    // Get WETH and approve
    await owner.sendTransaction({ to: wethAddress, value: amount })
    await wethContract.approve(dexHandler.address, amount);

    // Swap WETH to CRV
    await dexHandler.customSwap(swapDataWethCrv, amount);
    const crvBalance3 = await crvContract.callStatic.balanceOf(owner.address);

    // Send CRV to strategy
    await crvContract.transfer(mockStrategy.address, crvBalance3)

    // Default harvest
    await mockStrategy.oldHarvest();

    const strategyDaiBalance3 = await daiContract.callStatic.balanceOf(mockStrategy.address);

    console.log({ strategyDaiBalance3: strategyDaiBalance3.toNumber() })
    
  });

});
