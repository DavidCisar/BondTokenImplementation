const Documents = artifacts.require("DocumentContract");

module.exports = function (deployer) {
  deployer.deploy(Documents);
};
