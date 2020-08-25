pragma solidity ^0.5.11;

import "./GSN/Context.sol";
import "./token/MarsToken.sol";
import "./token/ERC/SafeERC20.sol";
import "./token/ERC/IERC20Receiver.sol";
import "./utils/Ownable.sol";
import "./utils/BytesLib.sol";
import "./math/SafeMath.sol";

contract Market is Context, IERC20Receiver, Ownable {
    using SafeMath for uint256;
    using BytesLib for bytes;
    using SafeERC20 for IERC20;

    enum ProductStatus { enable, sold }

    struct Product {
        uint256 id;
        uint256 price;
        address owner;
        uint8 status; // 0 : enable, 1 : sold
        uint index;
    }

    event MarsTokenChanged(address contractAddress);

    event SellProduct(address owner, uint256 id, uint256 price);
    event BuyProduct(address seller, address buyer, uint256 id, uint256 price);
    event CancelProduct(address owner, uint256 id);
    event CalcProducts(address owner, uint256 amount, uint256[] ids);

    uint256 private _feeNumerator = 5;
    uint256 private _feeDenominator = 100;
    uint256 private _minimumPrice = 1000000;

    mapping(uint256 => Product) private _products;
    mapping(uint256 => address) private _soldProducts;
    mapping(address => uint256) private _salesCount;
    uint256 private _takeableFee;
    uint256[] private _productKeys;

    IERC20 public _token;

    constructor(address token) public {
        setERC20TokenContract(token);
    }

    function exists(uint256 id) external view returns (bool) {
        return _exists(id);
    }

    function _exists(uint256 id) internal view returns (bool) {
        if (_products[id].price == 0)
            return false;

        return _products[id].status == uint8(ProductStatus.enable);
    }

    function getProductInfo(uint256 tradeId) external view returns (uint256 price, address owner, uint8 status) {
        return (_products[tradeId].price, _products[tradeId].owner, _products[tradeId].status);
    }

    function getProductInfoIndex(uint index) external view returns (uint256 id, uint256 price, address owner, uint8 status) {
        require(index < _productKeys.length, "out of length");
        uint256 tradeId = _productKeys[index];
        return (_products[tradeId].id, _products[tradeId].price, _products[tradeId].owner, _products[tradeId].status);
    }

    function getProductCount() external view returns (uint) {
        return _productKeys.length;
    }

    function _removeProductKey(uint index) internal {
        require (index < _productKeys.length, "out of length");

        uint lastIndex = _productKeys.length.sub(1);
        if (lastIndex != index) {
            uint256 lastId = _productKeys[lastIndex];
            _productKeys[index] = lastId;
            _products[lastId].index = index;
        }
        _productKeys.length--;
    }

    function registProduct(address operator, uint256 tradeId, uint256 price) external onlyOwner {
        require (_exists(tradeId) == false, "product is existing");
        require (_salesCount[operator] < 30, "30 count limit for sale");
        require (_minimumPrice <= price, "be more than 1000000 in price");

        _products[tradeId] = Product({
            id: tradeId,
            price: price,
            owner: operator,
            status: uint8(ProductStatus.enable),
            index: _productKeys.length
        });
        _productKeys.push(tradeId);
        _salesCount[operator]++;

        emit SellProduct(_products[tradeId].owner, _products[tradeId].id, _products[tradeId].price);
    }

    // buy
    function onERC20Received(address from, uint256 amount, bytes calldata data) external returns (bool) {
        require (_msgSender() == address(_token), "msg.sender is not token address");

        uint256 id = data.toUint(0);
        require (_exists(id), "item with input tokenId doesn't existing");

        Product storage product = _products[id];
        require (product.price == amount, "input amount is not valid");
        require (from != product.owner, "input buyer is not valid");
        
        product.status = uint8(ProductStatus.sold);
        _salesCount[product.owner]--;
        _soldProducts[id] = product.owner;

        emit BuyProduct(product.owner, from, id, amount);
        return true;
    }

    function cancelProduct(address operator, uint256 tradeId) external onlyOwner {
        require (_exists(tradeId) == true, "product doesn't existing");

        Product storage product = _products[tradeId];
        require (operator == product.owner, "operator is not product owner");

        _removeProductKey(product.index);
        _salesCount[operator]--;
        delete _products[tradeId];

        emit CancelProduct(operator, tradeId);
    }

    function calculateProduct(address operator, uint256[] calldata ids) external onlyOwner {
        require(ids.length > 0, "requested trade ids is empty");
        uint256 amount = 0;
        for(uint256 i = 0 ; i < ids.length ; i++) {
            require(_soldProducts[ids[i]] == operator, "it's not the operator's");
            uint256 fee = _products[ids[i]].price.divCeil(_feeDenominator).mul(_feeNumerator);
            _takeableFee = _takeableFee.add(fee);
            amount += _products[ids[i]].price.sub(fee);

            _removeProductKey(_products[ids[i]].index);
            delete _soldProducts[ids[i]];
            delete _products[ids[i]];
        }

        _token.safeTransfer(operator, amount);
        emit CalcProducts(operator, amount, ids);
    }

    // admin functions
    function setERC20TokenContract(address addr) public onlyOwner {
        require (_productKeys.length == 0, "Makret has products");

        _token = IERC20(addr);
        emit MarsTokenChanged(addr);
    }

    // fee from owner for market independently
    function takeTokenFee(address to, uint256 amount) external onlyOwner {
        require (0 < _takeableFee, "No more fees left");
        require (amount <= _takeableFee, "Request amount greater than saved fee");

        _takeableFee = _takeableFee.sub(amount);
        _token.safeTransfer(to, amount);
    }

    function setFee(uint256 numerator, uint256 denominator) external onlyOwner {
        _feeNumerator = numerator;
        _feeDenominator = denominator;
    }

    function setMinimumPrice(uint256 price) external onlyOwner {
        require (0 < price, "required 0 < price");
        _minimumPrice = price;
    }
}