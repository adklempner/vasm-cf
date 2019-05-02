const tdr = require("truffle-deploy-registry");

const VASMApp = artifacts.require("VASMApp");

const ARTIFACTS = [
  VASMApp
];

module.exports = (deployer, network) => {
  deployer.then(async () => {
    for (const artifact of ARTIFACTS) {
      const instance = await deployer.deploy(artifact);
      if (!tdr.isDryRunNetworkName(network)) {
        await tdr.appendInstance(instance);
      }
    }
  });
};
