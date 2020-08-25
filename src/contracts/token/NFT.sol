pragma solidity ^0.5.11;

import "./KIP17/KIP17Full.sol";
import "../utils/Ownable.sol";
import "../utils/Address.sol";
import "../math/SafeMath.sol";

contract NFT is KIP17Full, Ownable {
    using SafeMath for uint256;
    using Address for address;

    event Burn(uint256 id);

    uint256 private _finalTokenId = 0;

    constructor (string memory name, string memory symbol) KIP17Full(name, symbol) public {
    }

    function _generateTokenId() internal returns (uint256) {
        return ++_finalTokenId;
    }

    function _uint256ToString(uint256 v) internal pure returns (string memory) {
        if (v == 0) {
            return "0";
        }
        uint256 j = v;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (v != 0) {
            bstr[k--] = byte(uint8(48 + v % 10));
            v /= 10;
        }
        return string(bstr);
    }

    function createItem(address to, string calldata jsonUrl) external onlyOwner returns (uint256) {
        uint256 id = _generateTokenId();
        bytes memory burl = abi.encodePacked(jsonUrl, _uint256ToString(id));
        _mint(to, id);
        _setTokenURI(id, string(burl));
        return id;
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function ownerTokenLength(address owner) external view returns (uint256) {
        return _tokensOfOwner(owner).length;
    }

    function burnItem(uint256 tokenId) external {
        _burnItem(tokenId);
    }

    function _burnItem(uint256 tokenId) internal {
        require (_isApprovedOrOwner(_msgSender(), tokenId), "msg.sender is not token owner");
        _burn(_msgSender(), tokenId);
        emit Burn(tokenId);
    }
}