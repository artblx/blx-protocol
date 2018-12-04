pragma solidity ^0.5.0;

import "../Proxy/Proxy.sol";
import "./BLX20Data.sol";

contract BLX20Proxy is Proxy, BLX20Data {
    constructor(
        address proxied,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply,
        address issuer
    )
        public
        Proxy(proxied)
    {
        _factory = msg.sender;
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _issuer = issuer;

        emit InitializationStarted(_name, _symbol, totalSupply, _decimals);
    }
}
