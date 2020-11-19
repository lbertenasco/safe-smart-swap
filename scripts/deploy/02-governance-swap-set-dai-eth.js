const Confirm = require('prompt-confirm');
const hre = require('hardhat');
const ethers = hre.ethers;
const config = require('../../.config.json');
const { e18 } = require('../../utils/web3-utils');

const prompt = new Confirm('Do you wish to add default dai/weth governance handler and data?');

async function main() {
  await hre.run('compile');

  await promptAndSubmit();
}

function promptAndSubmit() {
  return new Promise(async (resolve) => {
    try {
      const [owner] = await ethers.getSigners();
      console.log('owner:', owner.address);
      prompt.ask(async (answer) => {
        if (answer) {

          const governanceSwap = await ethers.getContractAt('GovernanceSwap', config.contracts.mainnet.governanceSwap.address);
          const uniswapDexHandler = await ethers.getContractAt('UniswapV2DexHandler', config.contracts.mainnet.uniswapHandler.address);
          const uniswapV2Address = config.contracts.mainnet.uniswapV2Router.address;

          const daiAddress = config.contracts.mainnet.dai.address;
          const wethAddress = config.contracts.mainnet.weth.address;
          const path = [daiAddress, wethAddress];
          const defaultSwapData = await uniswapDexHandler.callStatic.customSwapData(
            0, // _amount
            0, // _min
            path, // _path
            owner.address, // _to
            0// _expire
          );
          await governanceSwap.setPairDefaults(daiAddress, wethAddress, uniswapV2Address, defaultSwapData);
          const pairDefaultDex = await governanceSwap.callStatic.getPairDefaultDex(daiAddress, wethAddress);
          console.log('dex is the same', config.contracts.mainnet.uniswapV2Router.address == pairDefaultDex)
          const pairDefaultDexHandler = await governanceSwap.callStatic.getPairDefaultDexHandler(daiAddress, wethAddress);
          console.log('handler is the same', config.contracts.mainnet.uniswapHandler.address == pairDefaultDexHandler)
          const pairDefaultData = await governanceSwap.callStatic.getPairDefaultData(daiAddress, wethAddress);
          const customDecodeData = await uniswapDexHandler.callStatic.customDecodeData(pairDefaultData);
          console.log('path is the same', JSON.stringify(path) == JSON.stringify(customDecodeData._path));

          resolve();
        } else {
          console.error('Aborted!');
          resolve();
        }
      });
    } catch (err) {
      reject(err);
    }
  });
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
