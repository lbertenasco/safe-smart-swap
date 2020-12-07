const Confirm = require('prompt-confirm');
const hre = require('hardhat');
const ethers = hre.ethers;
const config = require('../../.config.json');
const { e18 } = require('../../utils/web3-utils');

const prompt = new Confirm('Do you wish to add default weth/dai governance handler and data?');

async function main() {
  await hre.run('compile');

  await promptAndSubmit();
}

function promptAndSubmit() {
  return new Promise(async (resolve) => {
    try {
      const [owner] = await ethers.getSigners();
      console.log('owner:', owner.address);
      const deployer = owner;
      // await hre.network.provider.request({ method: "hardhat_impersonateAccount", params: [config.accounts.mainnet.deployer] });
      // const deployer = owner.provider.getUncheckedSigner(config.accounts.mainnet.deployer);
      prompt.ask(async (answer) => {
        if (answer) {

          const governanceSwap = await ethers.getContractAt('GovernanceSwap', config.contracts.mainnet.governanceSwap.address, deployer);
          const uniswapDexHandler = await ethers.getContractAt('UniswapV2DexHandler', config.contracts.mainnet.uniswapHandler.address, deployer);
          const uniswapV2Address = config.contracts.mainnet.uniswapV2Router.address;

          const daiAddress = config.contracts.mainnet.dai.address;
          const wethAddress = config.contracts.mainnet.weth.address;
          const tokenIn = wethAddress;
          const tokenOut = daiAddress;

          const path = [tokenIn, tokenOut];
          const defaultSwapData = await uniswapDexHandler.callStatic.customSwapData(
            0, // _amount
            0, // _min
            path, // _path
            owner.address, // _to
            0// _expire
          );
          await governanceSwap.setPairDefaults(tokenIn, tokenOut, uniswapV2Address, defaultSwapData);
          const pairDefaultDex = await governanceSwap.callStatic.getPairDefaultDex(tokenIn, tokenOut);
          console.log('dex is the same', config.contracts.mainnet.uniswapV2Router.address == pairDefaultDex)
          const pairDefaultDexHandler = await governanceSwap.callStatic.getPairDefaultDexHandler(tokenIn, tokenOut);
          console.log('handler is the same', config.contracts.mainnet.uniswapHandler.address == pairDefaultDexHandler)
          const pairDefaultData = await governanceSwap.callStatic.getPairDefaultData(tokenIn, tokenOut);
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
