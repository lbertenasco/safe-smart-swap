const Confirm = require('prompt-confirm');
const hre = require('hardhat');
const ethers = hre.ethers;
const config = require('../../.config.json');
const { e18 } = require('../../utils/web3-utils');

const prompt = new Confirm('Do you wish to deploy governance swap contract with uni+sushi handlers?');

async function main() {
  await hre.run('compile');
  const GovernanceSwap = await ethers.getContractFactory('GovernanceSwap');
  const UniswapV2DexHandler = await ethers.getContractFactory('UniswapV2DexHandler');

  await promptAndSubmit(GovernanceSwap, UniswapV2DexHandler);
}

function promptAndSubmit(GovernanceSwap, UniswapV2DexHandler) {
  return new Promise((resolve) => {
    try {
      prompt.ask(async (answer) => {
        if (answer) {
          console.time('GovernanceSwap deployed');
          const governanceSwap = await GovernanceSwap.deploy();
          console.timeEnd('GovernanceSwap deployed');

          console.log('GovernanceSwap address:', governanceSwap.address);


          // uni
          console.time('uniswap deployed and add handler');
          const uniswapV2Address = config.contracts.mainnet.uniswapV2Router.address;
          const uniswapV2DexHandler = await UniswapV2DexHandler.deploy(uniswapV2Address);

          console.log(`addDexHandler: dex ${uniswapV2Address} - handler ${uniswapV2DexHandler.address}`)
          await governanceSwap.addDexHandler(uniswapV2Address, uniswapV2DexHandler.address);
          console.timeEnd('uniswap deployed and add handler');


          // sushi
          console.time('sushiswap deployed and add handler');
          const sushiswapAddress = config.contracts.mainnet.sushiswapRouter.address;
          const sushiswapDexHandler = await UniswapV2DexHandler.deploy(sushiswapAddress);

          console.log(`addDexHandler: dex ${sushiswapAddress} - handler ${sushiswapDexHandler.address}`)
          await governanceSwap.addDexHandler(sushiswapAddress, sushiswapDexHandler.address);
          console.timeEnd('sushiswap deployed and add handler');


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
