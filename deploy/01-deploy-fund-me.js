// function deployFunc(hre) {
//   console.log("Hi");
// }

const { network } = require("hardhat");
const { networkConfig } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");
const { developmentChains } = require("../helper-hardhat-config");
// module.exports.default = deployFunc;

// hre== hardhat run time evnviroment
// hre variables can be found like this too
// module.exports= async ({getNamedAccounts, deployments})=>{
module.exports = async (hre) => {
  const { getNamedAccounts, deployments } = hre;
  //getNamedAccounts=hre.getNamedAccounts
  //deployments=hre.deployments
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;
  //const ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
  let ethUsdPriceFeedAddress;
  if (developmentChains.includes(network.name)) {
    const ethUsdAggregator = await deployments.get("MockV3Aggregator");
    ethUsdPriceFeedAddress = ethUsdAggregator.address;
  } else {
    ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
  }
  const args = [ethUsdPriceFeedAddress];
  const fundMe = await deploy("FundMe", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });
  //verify
  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(fundMe.address, args);
  }
};

module.exports.tags = ["all", "fundme"];
