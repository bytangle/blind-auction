const BlindAuction = artifacts.require("BlindAuction");

module.exports = (deployer) => {
    deployer.deploy(BlindAuction);
}