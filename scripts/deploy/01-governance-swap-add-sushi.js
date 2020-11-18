const Confirm = require('prompt-confirm');
const hre = require('hardhat');
const ethers = hre.ethers;
const config = require('../../.config.json');
const { e18 } = require('../../utils/web3-utils');

const prompt = new Confirm('Do you wish to add sushi handler?');

async function main() {
  await hre.run('compile');

  await promptAndSubmit();
}

function promptAndSubmit() {
  return new Promise((resolve) => {
    try {
      prompt.ask(async (answer) => {
        if (answer) {
          // const [owner] = await ethers.getSigners();
          // await hre.network.provider.request({ method: "hardhat_impersonateAccount", params: [config.accounts.mainnet.deployer] });
          // const deployer = owner.provider.getUncheckedSigner(config.accounts.mainnet.deployer);

          const governanceSwap = await ethers.getContractAt('GovernanceSwap', config.contracts.mainnet.governanceSwap.address);
          const sushiswapDexHandler = await ethers.getContractAt('UniswapV2DexHandler', config.contracts.mainnet.sushiswapHandler.address);

          const sushiswapAddress = config.contracts.mainnet.sushiswapRouter.address;
          await governanceSwap.addDexHandler(sushiswapAddress, sushiswapDexHandler.address);


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
