import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer, weth} = await getNamedAccounts();
  const tokenIn = (await deployments.get('TokenIn')).address;
  const tokenOut = (await deployments.get('TokenOut')).address;

  await deploy('TokenVendor', {
    from: deployer,
    args: [weth, tokenIn, tokenOut, deployer, 12, 100],
    log: true,
  });
};
export default func;
func.tags = ['TokenVendor'];
