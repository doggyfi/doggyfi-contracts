var DoggyToken = artifacts.require("DoggyToken");
var DoggyReferral = artifacts.require("DoggyReferral");
var MasterChef = artifacts.require("MasterChef");
var Timelock = artifacts.require("Timelock");

module.exports = async function(deployer) {
    let doggyaddress = await deployer.deploy(DoggyToken);
    deployer.deploy(DoggyReferral, DoggyToken.address);
    deployer.deploy(MasterChef, DoggyToken.address, 14100000);
    deployer.deploy(Timelock, '0xADBaB4F38Ff9DCD71886f43B148bcad4A3081fB9', 86400);
    
    };
