const KYC = artifacts.require("KycContract");

module.exports = function (deployer) {
  deployer.deploy(KYC);
};
