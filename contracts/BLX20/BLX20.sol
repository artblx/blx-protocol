pragma solidity ^0.5.0;

import "../../openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";

import "../BLXFactory/IBLXFactory.sol";
import "./BLX20Data.sol";

contract BLX20 is BLX20Data {
    function factory() public view returns(address) {
        return _factory;
    }

    function issuer() public view returns(address) {
        return _issuer;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function parentToken() public view returns(address) {
        return _parentToken;
    }

    function parentTokenId() public view returns(uint256) {
        return _parentTokenId;
    }

    function utilityTransferFrom(address from, address to, uint256 value) public returns (bool) {
        require(
            IBLXFactory(factory()).isValidUtilityContract(msg.sender),
            "Sender is not a Valid Utility Contact"
        );
        _transfer(from, to, value);
        return true;
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

        // Set parent NFT address and ID
        _parentToken = msg.sender;
        _parentTokenId = _tokenId;
        emit ParentTokenReceived(msg.sender, _tokenId);

        // Mint and transfer balance to issuer
        _mint(issuer(), _totalSupply);

        // And we're done
        emit InitializationComplete(name(), symbol(), totalSupply(), decimals());

        return IERC721Receiver(address(0)).onERC721Received.selector;
    }
}
