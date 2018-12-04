const Migrations = artifacts.require("./Migrations.sol");

const ERC20MintableA = artifacts.require("ERC20MintableA.sol");
const ERC20MintableB = artifacts.require("ERC20MintableB.sol");
const ERC721Mintable = artifacts.require("./ERC721Mintable.sol");
const BLX20 = artifacts.require("./BLX20.sol");
const BLXDex = artifacts.require("./BLXDex.sol");
const BLXFactory = artifacts.require("./BLXFactory.sol");

module.exports = async deployer => {
    await deployer.deploy(ERC721Mintable, "NFT for testing", "ERC721");
    await deployer.deploy(ERC20MintableA);
    await deployer.deploy(ERC20MintableB);
    await deployer.deploy(BLX20);
    await deployer.deploy(BLXDex);
    await deployer.deploy(BLXFactory, BLX20.address, BLXDex.address);

    return;
};
