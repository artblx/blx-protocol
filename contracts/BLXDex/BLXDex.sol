pragma solidity ^0.5.0;


//import {IERC20 as ERC20} from "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/master/contracts/token/ERC20/IERC20.sol";
//import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/master/contracts/math/SafeMath.sol";
import {IERC20 as ERC20} from "../../openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";

contract BLXDex is ReentrancyGuard {
    using SafeMath for uint256;

    // Precision boost within uint256
    uint256 constant public BOOST = 10 ** 38;
    uint256 constant public OVER_BOOST = BOOST ** 2; // 10 ** 76

    function reverse(uint256 _price) pure public returns (uint256) {
        return OVER_BOOST / _price;
    }

    function convert(uint256 _amount, uint256 _price) pure public returns (uint256) {
        // _amount * _price / BOOST
        return _amount.mul(_price).div(BOOST);
    }


    struct Bid {
        address wallet;
        uint256 amount;
        uint256 price;
        bytes32 next; // Linked list, next equal/lower priced bid
    }

    struct Bids {
        bytes32 top; // Linked list, top price bid
        mapping(bytes32 => Bid) bids;
    }


    mapping(address => mapping(address => Bids)) public pairs;


    event BidPlaced(address Token, address Currency, address wallet, uint256 amount, uint256 price, bytes32 id);
    event BidPartiallyFilled(address Token, address Currency, address maker, address taker, uint256 amount, uint256 price);
    event BidFilled(address Token, address Currency, address maker, address taker, uint256 amount, uint256 price);
    event BidCanceled(address Token, address Currency, address wallet, uint256 amount, uint256 price);


    // Input validation
    modifier distinct(address A, address B) {
        require(A != B, "Same address");
        _;
    }
    modifier positive(uint256 _amount) {
        require(_amount > 0, "Invalid input");
        _;
    }


    function marketBuy(
        address _Token, // token to buy
        address _Currency, // currency to pay with
        uint256 _currencyAmount // currency amount to spend, should be approved
    ) nonReentrant() positive(_currencyAmount) public {
        // Filling orders as bids of opposite pair
        fillBids(_Currency, _Token, _currencyAmount, 0);
    }

    function limitBuy(
        address _Token, // token to buy
        address _Currency, // currency to pay with
        uint256 _amount, // token amount, but convert(_amount, _price) of currency should be approved
        uint256 _price, // price in _Currency per 1e+38 _Token
        uint256 _nonce, // for unique hash
        bytes32 _after
    ) nonReentrant() positive(_amount) positive(_price) public {
        // Adjusting _amount after filling orders
        (, uint256 tokenReceived) =
            fillBids(_Currency, _Token, convert(_amount, _price), reverse(_price));
        _amount = _amount.sub(tokenReceived);
        if (_amount > 0)
            placeBid(_Token, _Currency, _amount, _price, _nonce, _after);
    }


    function marketSell(
        address _Token, // token to sell
        address _Currency, // currency to get paid with
        uint256 _amount // token amount to sell
    ) nonReentrant() positive(_amount) public {
        fillBids(_Token, _Currency, _amount, 0);
    }


    function limitSell(
        address _Token, // token to sell
        address _Currency, // currency to get paid with
        uint256 _amount, // token amount
        uint256 _price, // price in _Currency per 1e+38 _Token; if 0: market price,
        uint256 _nonce, // for unique hash
        bytes32 _after // optional to skip
    ) nonReentrant() positive(_amount) positive(_price) public {
        (_amount,) = fillBids(_Token, _Currency, _amount, _price);
        if (_amount > 0)
        // Placing order as a bid of opposite pair
            placeBid(_Currency, _Token, convert(_amount, _price), reverse(_price), _nonce, _after);
    }


    function placeBid(
        address _Token, // to buy
        address _Currency, // to pay with
        uint256 _tokenAmount, // Token amount
        uint256 _price, // price in _Currency per 1e+38 _Token
        uint256 _nonce, // for unique hash
        bytes32 _after  // (optional) to reduce iteration over bids
                        // ideally hash of the last bid with equal or higher price
    ) distinct(_Token, _Currency) private {

        // Locating data in storage
        Bids storage pair = pairs[_Token][_Currency];
        mapping(bytes32 => Bid) storage bids = pair.bids;
        // Generating unique id
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _tokenAmount, _price, _nonce));
        require(bids[hash].amount == 0, "Duplicate exists");

        if (_after == bytes32(0) || _price > bids[_after].price) {
            // Starting from top if _after is unset or misplaced
            _after = pair.top;
        }

        Bid storage placeAfter = bids[_after];

        // if top price is higher or equal than offered _price
        if (_price <= placeAfter.price) {
            Bid storage next = bids[placeAfter.next];

            // Iterating to find a bid with lower price
            while (_price <= next.price) {
                placeAfter = next;
                next = bids[placeAfter.next];
            }
            // Placing bid before the one with lower price
            bids[hash] = Bid(msg.sender, _tokenAmount, _price, placeAfter.next);
            placeAfter.next = hash;

        } else {
            // Placing new order as top if _price is the highest
            bids[hash] = Bid(msg.sender, _tokenAmount, _price, pair.top);
            pair.top = hash;
        }

        // 💸💸💸
        require(ERC20(_Currency).transferFrom(msg.sender, address(this), convert(_tokenAmount, _price)),
            "Transfer failed");
        emit BidPlaced(_Token, _Currency, msg.sender, _tokenAmount, _price, hash);
    }


    function fillBids(
        address _Token, // token to sell
        address _Currency, // currency to get paid with
        uint256 _tokenAmount, // token amount to spend
        uint256 _priceLimit // price limit in _Currency per 1e+38 _Token; if 0: market price,
    ) distinct(_Token, _Currency) private returns (uint256, uint256){

        // Locating data in storage
        Bids storage pair = pairs[_Token][_Currency];
        mapping(bytes32 => Bid) storage bids = pair.bids;
        bytes32 top = pair.top;
        Bid memory bid = bids[top];
        uint256 currencyTransfer = 0;

        // Iterating trough bids
        while (_tokenAmount > 0 && bid.price >= _priceLimit && bid.amount > 0) {
            if (_tokenAmount < bid.amount) {
                // Filling partially
                bid.amount -= _tokenAmount;

                // Moving funds
                currencyTransfer = currencyTransfer.add(convert(_tokenAmount, bid.price));
                require(ERC20(_Token).transferFrom(msg.sender, bid.wallet, _tokenAmount));
                _tokenAmount = 0;

                emit BidPartiallyFilled(_Token, _Currency, bid.wallet, msg.sender, _tokenAmount, bid.price);
            } else {
                // Filling bid completely
                _tokenAmount -= bid.amount;

                // Moving funds
                currencyTransfer = currencyTransfer.add(convert(bid.amount, bid.price));
                require(ERC20(_Token).transferFrom(msg.sender, bid.wallet, bid.amount));

                emit BidFilled(_Token, _Currency, bid.wallet, msg.sender, bid.amount, bid.price);

                top = bid.next;
                bid = bids[top];
            }
        }

        if (top != pair.top)
            pair.top = top;

        if (currencyTransfer > 0)
            require(ERC20(_Currency).transfer(msg.sender, currencyTransfer));

        return (_tokenAmount, currencyTransfer);
    }



    function cancelBid(
        address _Token, // to buy
        address _Currency, // to pay with
        bytes32 _id, // bids hash
        bytes32 _after  // (optional) to reduce iteration over bids
    // ideally hash of the last bid with equal or higher price
    ) distinct(_Token, _Currency) public {

        // Locating data in storage
        Bids storage pair = pairs[_Token][_Currency];
        mapping(bytes32 => Bid) storage bids = pair.bids;
        Bid memory bid = bids[_id];
        bool willDelete = false;

        if (pair.top == _id) {
            pair.top = bid.next;
            willDelete = true;
        } else {

            if (_after == bytes32(0) || bids[_after].price == 0) {
                // Starting from top if _after is unset or misplaced
                _after = pair.top;
            }


            // Iterating to find a bid pointing to _id
            Bid storage removeAfter = bids[_after];
            while (removeAfter.price > 0) {
                if (removeAfter.next == _id) {
                    removeAfter.next = bid.next;
                    willDelete = true;
                    break;
                }
                removeAfter = bids[removeAfter.next];
            }

        }

        if (willDelete) {
            require(msg.sender == bid.wallet, "Wrong wallet");
            require(ERC20(_Currency).transfer(msg.sender, convert(bid.amount, bid.price)),
                "Transfer failed");
            emit BidCanceled(_Token, _Currency, msg.sender, bid.amount, bid.price);
            delete bids[_id];
        }
    }
}
