pragma solidity ^0.5.0;

import "../../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

contract ERC721Mintable is ERC721 {
    using SafeMath for uint256;

    uint256 tokenCount;

    event Minted(address owner, uint256 id);

    function mint() public returns(uint256 id) {
        id = tokenCount.add(1);
        _mint(msg.sender, id);
        emit Minted(msg.sender, id);
    }
}
