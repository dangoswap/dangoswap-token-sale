import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer} = await getNamedAccounts();

  await deploy('TokenIn', {
    from: deployer,
    args: ['tokenIn Token', 'TI', '200000000000000000000000000'],
    contract: 'MockERC20',
    log: true,    
  });

  await deploy('TokenOut', {    
    from: deployer,
    args: ['tokenOut Token', 'TO', '200000000000000000000000000'],
    contract: 'MockERC20',
    log: true,    
  });
};
export default func;
func.tags = ['TokenInOut'];