pragma solidity ^0.5.0;

import "../../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "../../openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";

import "../BLX20/BLX20Proxy.sol";

contract BLXFactory {
    using SafeMath for uint256;

    address blxDexAddress;
    address private masterBlx20Address;

    mapping(address => bool) validUtilityContracts;
    mapping(address => mapping(uint256 => address)) tokenToBlx20;

    event GeneratedBLX20(address token, uint256 tokenId, address blx20);

    constructor(
        address _masterBlx20Address,
        address _blxDexAddress
    ) public {
        blxDexAddress = _blxDexAddress;
        masterBlx20Address = _masterBlx20Address;

        validUtilityContracts[blxDexAddress] = true;
    }

    function isValidUtilityContract(address test) public view returns(bool) {
        return validUtilityContracts[test];
    }

    function getBlx20(
        address _token,
        uint256 _tokenId
    )
        public
        view
        returns(address)
    {
        return tokenToBlx20[_token][_tokenId];
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
        assert(_operator == _from);
        assert(tokenToBlx20[msg.sender][_tokenId] == address(0));

        (
            string memory name,
            string memory symbol,
            uint8 decimals,
            uint256 totalSupply
        ) = abi.decode(_data, (string, string, uint8, uint256));

        // Generate BLX20
        address blx20 = address(
            new BLX20Proxy(
                masterBlx20Address,
                name,
                symbol,
                decimals,
                totalSupply,
                _from
            )
        );

        // Save the BLX20 reference for lookup
        tokenToBlx20[msg.sender][_tokenId] = blx20;

        // Send the NFT to the BLX20
        IERC721(msg.sender).approve(blx20, _tokenId);
        IERC721(msg.sender).safeTransferFrom(address(this), blx20, _tokenId, abi.encode(totalSupply));

        emit GeneratedBLX20(msg.sender, _tokenId, blx20);

        return IERC721Receiver(address(0)).onERC721Received.selector;
    }
}
