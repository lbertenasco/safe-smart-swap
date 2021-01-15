const Confirm = require('prompt-confirm');
const hre = require('hardhat');
const ethers = hre.ethers;
const config = require('../../.config.json');
const { e18 } = require('../../utils/web3-utils');

const prompt = new Confirm('Do you wish to deploy governance swap contract with uni+sushi handlers?');

async function main() {
  await hre.run('compile');
  const DefaultHandler = await ethers.getContractFactory('DefaultHandler');

  await promptAndSubmit(DefaultHandler);
}

function promptAndSubmit(DefaultHandler) {
  return new Promise((resolve) => {
    try {
      prompt.ask(async (answer) => {
        if (answer) {
          console.time('DefaultHandler deployed');
          const uniswapV2Address = config.contracts.mainnet.uniswapV2Router.address;
          const defaultHandler = await DefaultHandler.deploy(uniswapV2Address);
          console.timeEnd('DefaultHandler deployed');

          console.log('DefaultHandler address:', defaultHandler.address);

          const governanceSwap = await ethers.getContractAt('GovernanceSwap', config.contracts.mainnet.governanceSwap.address);
          await governanceSwap.setDefaultHandler(defaultHandler.address);

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
