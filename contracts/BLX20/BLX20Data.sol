pragma solidity ^0.5.0;

import "./BLX20Header.sol";
import "../Proxy/ProxyData.sol";

contract BLX20Data is ProxyData, BLX20Header {
    address internal _factory;
    address internal _issuer;
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    address internal _parentToken;
    uint256 internal _parentTokenId;
}
