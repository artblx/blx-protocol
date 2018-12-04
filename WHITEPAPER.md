# BLX Protocol Whitepaper

BLX Protocol is an open-source, decentralized platform for refungible tokens on the Ethereum network.

### Refungible Tokens (RFTs)

Shared ownership occurs across many industries and for many reasons. As more assets are registered, regulated and/or represented by the ERC-721 Non-Fungible Token Standard there will be more instances where the need for shared ownership of these assets will arise.

The fungible tokens (RFTs) created from this process will have a value attached to the non-fungible tokens which they represent. This will be useful for price discovery of the underlying asset, liquidity for shared owners and as a new class of asset which can be used as collateral for loans or other financial instruments like stable coins. Providing an interface to this special class of fungible tokens is necessary to allow third parties to recognize them as such and to recognize when a non-fungible token is collectively owned.

This might be useful in the case of a wallet who would want to utilize the metadata of the underlying Non-Fungible Token (NFT) to show additional info next to an RFT, or on an exchange who might want to make that sort of info similarly available, or an NFT marketplace who may want to direct customers to a relevant exchange who wish to purchase shares in a NFT which is owned by an RFT. Anywhere an ERC-20 is applicable it would be useful for a user to know whether that token represents a shared NFT, and what attributes that NFT may have.

To facilitate this process, we at [ARTBLX](http://artblx.com) have created the BLX Protocol, a protocol for collective ownership of physical and digital assets.

## BLX-Factory

The entrypoint to the BLX Protocol is the BLX-Factory. The Factory houses references to our trustless liquidity instruments (discussed in full later), and more importantly, provides a means to generate an RFT (BLX-20) that can be used to interact with the contracts in the BLX Protocol ecosystem.

![](https://i.imgur.com/vsbXNNH.png)

To kick-off the creation of a new BLX-20, the owner of an ERC-721 compliant token transfers ownership of the token to the BLX-Factory smart contract using ERC-721's `safeTransferFrom()` function.

```javascript
erc721Instance.safeTransferFrom(
    _from, // Address of current token owner
    _to, // Address of BLX-Factory
    _tokenId, // ID of token to send
    _data // Encoded array of arguments for BLX-20
);
```

The final argument (`_data`) should be an encoded array of parameters which will be used when initializing the new BLX-20 token.

```javascript
const name = "Jean-Michel Basquiat, Early Moses, 1983";
const symbol = "BAS83X";
const decimals = "8";
const totalSupply = "100000000000000";

const _data = web3.eth.abi.encodeParameters(
    ["string", "string", "uint8", "uint256"],
    [name, symbol, decimals, totalSupply]
);
```

When the Factory receives an ERC-721 along with the encoded arguments, it will automatically generate a new BLX-20.

Once the BLX-20 is created, the Factory will transfer ownership of the ERC-721 to the BLX-20. When the BLX-20 receives the ERC-721, it mints the total supply of tokens and transfers the entire supply to the previous owner of the ERC-721 (the Issuer).

The Issuer now has the option to hold a dutch auction (using BLX-DUTCH) or submit a sell order (using BLX-DEX) to sell all or part of his shares. Once a token has more than one stakeholder, votes can be held to make collective decisions (using BLX-VOTE).

## BLX-20

The BLX-20 Refungible Token (RFT) represents collective ownership of an asset and can engage with the BLX Protocol’s trustless liquidity instruments for price discovery, trading, and governance.

The tokens are based on an extension of the ERC-20 token standard. They are fractional, interchangeable, and are owners of the parent ERC-721 Token.

```solidity
contract BLX20 is ERC20 {
    address private _factory;
    address private _issuer;
    address private _parentToken;
    uint256 private _parentTokenId;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply,
        address issuer
    ) public {
        _factory = msg.sender;
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _issuer = issuer;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    )
        public
        returns(bytes4)
    {
        assert(parentToken() == address(0));
        assert(parentTokenId() == 0);

        (uint256 _totalSupply) = abi.decode(_data, (uint256));

        _parentToken = msg.sender;
        _parentTokenId = _tokenId;

        _mint(issuer(), _totalSupply);

        return IERC721Receiver(address(0)).onERC721Received.selector;
    }
}

```

## BLX-DEX

BLX-DEX is a trading smart contract that allows BLX-20 Tokenholders to trade their tokens wallet to wallet. The order book is embedded within the smart contract so that the token’s potential to be traded is as decentralized as possible.

:::warning
More detailed information about BLX-DEX coming soon.
:::

## BLX-DUTCH

BLX-DUTCH is a price discovery smart contract that enables the issuer to arrange a Dutch auction. The issuers of BLX-20 tokens are effectively able to arrange their own mini ICO for their asset.

Sellers set the parameters of their auction by determining:

1. The % they would like to sell;
2. Their suggested start price per token;
3. And the lowest price they would accept per token.

:::warning
More detailed information about BLX-DUTCH coming soon.
:::

## BLX-VOTE

BLX-VOTE is a governance smart contract that enables the BLX-20 Tokenholder’s voting rights as a collective owner. In the event of a third party offer from outside the Protocol, for example to purchase the entire asset, the <51% tokenholders will be given the opportunity to vote in favor of or against the offer.

Tokenholders are ranked in descending order based upon the number of tokens held and they will be notified of the request with a designated amount of time to respond. If the Tokenholder is not able to submit a vote in the allotted amount of time, the vote will be considered as consent.

In general, BLX-20 tokens will be governed by a 51% majority vote with a 20% blocking right.

:::warning
More detailed information about BLX-VOTE coming soon.
:::

## EIP (ERC 1633)

As part of our commitment to open-source code, we have submitted an Ethereum Improvement Proposal (EIP) for a Re-Fungible Token Standard. The intention of our proposal, is to extend the ERC-20 Token Standard and utilize ERC-165 Standard Interface Detection in order to represent the shared ownership of an ERC-721 Non-Fungible Token. The ERC-20 Token Standard was modified as little as possible in order to allow this new class of token to operate in all of the ways and locations which are familiar to assets that follow the original ERC-20 specification.

While there are many possible variations of this specification that would enable many different capabilities and scenarios for shared ownership, our proposal is focused on the minimal commonalities to enable as much flexibility as possible for various further extensions.

View the pull-request for the EIP [here](https://github.com/ethereum/EIPs/pull/1633) and the request for comments [here](https://github.com/ethereum/EIPs/issues/1634).

## More information

Website: [blx.org](https://blx.org)
GitHub: [artblx/blx-protocol](https://github.com/artblx/blx-protocol)
