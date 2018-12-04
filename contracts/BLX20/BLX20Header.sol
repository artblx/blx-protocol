pragma solidity ^0.5.0;

import "../../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract BLX20Header is ERC20 {
    event InitializationStarted(string name, string symbol, uint256 totalSupply, uint8 decimals);
    event ParentTokenReceived(address parentToken, uint256 parentTokenId);
    event InitializationComplete(string name, string symbol, uint256 totalSupply, uint8 decimals);
}
