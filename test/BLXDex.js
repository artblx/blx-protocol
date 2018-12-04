const ERC20MintableA = artifacts.require("ERC20MintableA");
const ERC20MintableB = artifacts.require("ERC20MintableB");
const BLXDex = artifacts.require("BLXDex");

const toBN = web3.utils.toBN;
const boost = toBN(10).pow(toBN(38));
let nonce = 1;

contract("BLXDex", function(accounts) {
    let erc20A, erc20B;
    it("should deploy ERC20", async function() {
        erc20A = await ERC20MintableA.deployed();
        erc20B = await ERC20MintableB.deployed();
        assert(erc20A !== undefined, "ERC20A is not deployed");
        assert(erc20B !== undefined, "ERC20B is not deployed");

        let aMinted = await erc20A.mint(accounts[0], 1000000);
        let bMinted = await erc20B.mint(accounts[1], 1000000);
        assert(aMinted !== undefined, "ERC20A is not minted");
        assert(bMinted !== undefined, "ERC20B is not minted");
    });

    let BLXDexInstance;
    it("should deploy Dex", async function() {
        BLXDexInstance = await BLXDex.deployed();
        assert(BLXDexInstance !== undefined, "BLX721 is deployed");
    });

    it("ERC20 should approve Dex", async function() {
        let aApproved = await erc20A.approve(BLXDexInstance.address, 1000000, {
            from: accounts[0]
        });
        let bApproved = await erc20B.approve(BLXDexInstance.address, 1000000, {
            from: accounts[1]
        });
        assert(aApproved !== undefined, "ERC20A is not approved");
        assert(bApproved !== undefined, "ERC20B is not approved");
    });

    let orderResult;
    it("should place orders", async function() {
        for (let i = 0; i < 10; i++)
            orderResult = await BLXDexInstance.limitBuy(
                erc20A.address, // token to buy
                erc20B.address, // currency to pay with
                1000, // token amount, but convert(_amount, _price) of currency should be approved
                boost.clone().mul(toBN(2)), // price in _Currency per 1e+38 _Token
                nonce++, // for unique hash
                "0x0",
                { from: accounts[1] }
            );

        assert(
            orderResult.receipt.gasUsed < 152000,
            "10th order placement is gassy"
        );
    });

    it("should fill orders", async function() {
        orderResult = await BLXDexInstance.limitSell(
            erc20A.address, // token to sell
            erc20B.address, // currency to get paid with
            10000, // token amount, but convert(_amount, _price) of currency should be approved
            boost, // price in _Currency per 1e+38 _Token
            nonce++, // for unique hash
            "0x0",
            { from: accounts[0] }
        );

        let filledEvents = orderResult.logs.filter(
            ({ event }) => event === "BidFilled"
        );
        assert(
            orderResult.logs.length === 10 && filledEvents.length === 10,
            "should fill 10 orders"
        );
        assert(
            orderResult.receipt.gasUsed < 313000,
            "filling 10 orders is gassy"
        );

        let a1Balance = await erc20A.balanceOf(accounts[0]);
        let a2Balance = await erc20A.balanceOf(accounts[1]);
        let b1Balance = await erc20B.balanceOf(accounts[0]);
        let b2Balance = await erc20B.balanceOf(accounts[1]);

        // console.log(a1Balance.toNumber(), a2Balance.toNumber(), b1Balance.toNumber(), b2Balance.toNumber());

        assert(
            a1Balance.toNumber() === 99e4 &&
                a2Balance.toNumber() === 1e4 &&
                b1Balance.toNumber() === 2e4 &&
                b2Balance.toNumber() === 98e4,
            "balances are not correct"
        );
    });

    it("should cancel order", async function() {
        orderResult = await BLXDexInstance.limitBuy(
            erc20A.address, // token to buy
            erc20B.address, // currency to pay with
            10000, // token amount, but convert(_amount, _price) of currency should be approved
            boost, // price in _Currency per 1e+38 _Token
            nonce++, // for unique hash
            "0x0",
            { from: accounts[1] }
        );

        orderResult = await BLXDexInstance.cancelBid(
            erc20A.address, // token to buy
            erc20B.address, // currency to pay with
            orderResult.logs[0].args.id,
            "0x0",
            { from: accounts[1] }
        );

        let a1Balance = await erc20A.balanceOf(accounts[0]);
        let a2Balance = await erc20A.balanceOf(accounts[1]);
        let b1Balance = await erc20B.balanceOf(accounts[0]);
        let b2Balance = await erc20B.balanceOf(accounts[1]);

        // console.log(a1Balance.toNumber(), a2Balance.toNumber(), b1Balance.toNumber(), b2Balance.toNumber());

        assert(
            a1Balance.toNumber() === 99e4 &&
                a2Balance.toNumber() === 1e4 &&
                b1Balance.toNumber() === 2e4 &&
                b2Balance.toNumber() === 98e4,
            "balances are not correct"
        );
    });
});
