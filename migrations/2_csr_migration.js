const CSR = artifacts.require("CSRContract");

module.exports = function (deployer) {
  deployer.deploy(CSR);
};
