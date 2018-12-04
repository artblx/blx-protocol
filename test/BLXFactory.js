const { tokens } = require("./data");
const { gasToCash } = require("./utils");

const ERC721Mintable = artifacts.require("ERC721Mintable");
const BLXFactory = artifacts.require("BLXFactory");
const BLX20 = artifacts.require("BLX20");

contract("BLXFactory", function(accounts) {
    let totalGas = web3.utils.toBN("0");

    let blx721Instance;
    it("should have ERC721Mintable deployed", async function() {
        blx721Instance = await ERC721Mintable.deployed();
        assert(blx721Instance !== undefined, "ERC721Mintable is deployed");
    });

    let blxFactoryInstance;
    it("should have BLXFactory deployed", async function() {
        blxFactoryInstance = await BLXFactory.deployed();
        assert(blxFactoryInstance !== undefined, "BLXFactory is deployed");
    });

    let mintedResult;
    let mintedEvent;
    let mintedId;
    it("should mint a new ERC721Mintable token", async function() {
        mintedResult = await blx721Instance.mint({
            from: accounts[0]
        });

        mintedEvent = mintedResult.logs.filter(l => l.event === "Minted")[0];
        mintedId = mintedEvent.args.id.toNumber();

        assert(mintedId === tokens[0].tokenId, "has Minted a token");
    });

    // In progress...
    // let generatedResult;
    // it("should generate a new BLX20 token", async function() {
    //     const token = tokens[0];
    //     const data = web3.eth.abi.encodeParameters(
    //         ["string", "string", "uint8", "uint256"],
    //         Object.keys(token.args).map(key => token.args[key])
    //     );

    //     generatedResult = await blx721Instance.safeTransferFrom(
    //         accounts[0],
    //         BLXFactory.address,
    //         mintedId,
    //         data
    //     );

    //     console.log(generatedResult);

    //     console.log("getblx20", blx721Instance.address, token.tokenId);

    //     token.address = await blxFactoryInstance.getBlx20(
    //         blx721Instance.address,
    //         token.tokenId
    //     );

    //     console.log(token.address);

    //     gasToCash(generatedResult.receipt.gasUsed);
    //     totalGas += generatedResult.receipt.gasUsed;

    //     assert(token.address !== undefined, "has generated a BLX20");
    // });

    // let ownerOfResult;
    // it("should transfer the ERC721 to the new BLX20", async function() {
    //     const token = tokens[0];
    //     ownerOfResult = await blx721Instance.ownerOf(token.tokenId);
    //     assert(
    //         ownerOfResult === token.address,
    //         "has transfered the ERC721 to the BLX20"
    //     );
    // });

    // let balanceOfResult;
    // let blx20Instance;
    // it("should transfer the total supply of the new BLX20 to the issuer", async function() {
    //     const account = accounts[0];
    //     const token = tokens[0];
    //     blx20Instance = await BLX20.at(token.address);
    //     balanceOfResult = await blx20Instance.balanceOf(account);
    //     assert(
    //         `${balanceOfResult.toNumber()}` === token.args.totalSupply,
    //         "has transfered the total supply to the issuer"
    //     );
    // });
});
