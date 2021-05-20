// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract DogecoinCashNFT is ERC721, Ownable {
    address public _contractOwner;
    
    IERC20 public dogecoinCashToken;
    address public feeAddress;

    mapping (uint => uint) public price;
    mapping (uint => bool) public listedMap;

    event Purchase(address indexed previousOwner, address indexed newOwner, uint price, uint nftID, string uri);

    event Minted(address indexed minter, uint price, uint nftID, string uri);

    event PriceUpdate(address indexed owner, uint oldPrice, uint newPrice, uint nftID);

    event NftListStatus(address indexed owner, uint nftID, bool isListed);

    constructor() ERC721("Dogecoin Cash NFT", "DOGCT") {
        _contractOwner = msg.sender;
    }

    function setDogecoinCashToken(address _address) external onlyOwner {
        require(_address != address(0x0), "invalid address");
		dogecoinCashToken = IERC20(_address);
    }

    function mint(string memory _tokenURI, address _toAddress, uint _price) public returns (uint) {
        uint _tokenId = totalSupply() + 1;
        price[_tokenId] = _price;
        listedMap[_tokenId] = true;

        _safeMint(_toAddress, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);

        emit Minted(_toAddress, _price, _tokenId, _tokenURI);

        return _tokenId;
    }

    function buy(uint _id) external {
        _validate(_id);

        address _previousOwner = ownerOf(_id);
        address _newOwner = msg.sender;

        _trade(_id);

        emit Purchase(_previousOwner, _newOwner, price[_id], _id, tokenURI(_id));
    }

    function _validate(uint _id) internal {
        bool isItemListed = listedMap[_id];
        require(_exists(_id), "Error, wrong tokenId");
        require(isItemListed, "Item not listed currently");
        require(msg.value >= price[_id], "Error, the amount is lower");
        require(msg.sender != ownerOf(_id), "Can not buy what you own");
    }

    function _trade(uint _id) internal {
        address _buyer = msg.sender;
        address _owner = ownerOf(_id);

        // 2.5% commission cut
        uint _commissionValue = price[_id] / 40 ;
        uint _sellerValue = price[_id] - _commissionValue;

        require(dogecoinCashToken.transferFrom(_buyer, _contractOwner, _commissionValue), "Failed to transfer admin fee");
        require(dogecoinCashToken.transferFrom(_buyer, _owner, _sellerValue), "Failed to transfer admin fee");

        _transfer(_owner, _buyer, _id);

        listedMap[_id] = false;
    }

    function updatePrice(uint _tokenId, uint _price) public returns (bool) {
        uint oldPrice = price[_tokenId];
        require(msg.sender == ownerOf(_tokenId), "Error, you are not the owner");
        price[_tokenId] = _price;

        emit PriceUpdate(msg.sender, oldPrice, _price, _tokenId);
        return true;
    }

    function updateListingStatus(uint _tokenId, bool shouldBeListed) public returns (bool) {
        require(msg.sender == ownerOf(_tokenId), "Error, you are not the owner");

        listedMap[_tokenId] = shouldBeListed;

        emit NftListStatus(msg.sender, _tokenId, shouldBeListed);

        return true;
    }
}
