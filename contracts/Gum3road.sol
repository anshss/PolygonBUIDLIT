//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract Gum3road is ERC1155URIStorage, ERC1155Receiver {
    address payable owner;

    constructor() ERC1155("") {
        owner = payable(msg.sender);
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    struct ebook {
        uint256 tokenId;
        address payable owner;
        address payable creator;
        uint256 price;
        uint256 supply;
        uint256 supplyleft;
    }

    event ebookCreated(
        uint256 indexed tokenId,
        address owner,
        address creator,
        uint256 price,
        uint256 supply,
        uint256 supplyleft
    );

    mapping(uint256 => ebook) idToEbook;

    // ------------

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        this.onERC1155BatchReceived.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ------------

    function createToken(
        string memory tokenURI,
        uint256 supply,
        uint256 price
    ) public payable {
        _tokenId.increment();
        uint256 currentToken = _tokenId.current();
        _mint(msg.sender, currentToken, supply, "");
        _setURI(currentToken, tokenURI);
        createEbook(currentToken, supply, price);
    }

    function createEbook(
        uint256 tokenId,
        uint256 supply,
        uint256 price
    ) private {
        idToEbook[tokenId] = ebook(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            supply,
            supply
        );

        _safeTransferFrom(msg.sender, address(this), tokenId, supply, "");

        emit ebookCreated(
            tokenId,
            address(this),
            msg.sender,
            price,
            supply,
            supply
        );
    }

    function createSale(uint256 tokenId) public payable {
        uint256 price = idToEbook[tokenId].price;
        require(msg.value == price);
        require(idToEbook[tokenId].supplyleft >= idToEbook[tokenId].supply);
        idToEbook[tokenId].owner = payable(msg.sender);
        idToEbook[tokenId].supplyleft--;

        _safeTransferFrom(address(this), msg.sender, tokenId, 1, "");

        uint256 fee = 0.00029 ether;
        uint256 remaining = price - fee;

        payable(idToEbook[tokenId].creator).transfer(remaining);
        payable(owner).transfer(fee);
    }

    function fetchStore() public view returns (ebook[] memory) {
        ebook[] memory unsoldBooks;
        uint32 counter = 0;
        for (uint32 i = 0; i < _tokenId.current(); i++) {
            if (idToEbook[i].supplyleft > 0) {
                unsoldBooks[counter] = idToEbook[i];
                counter++;
            }
        }
        return unsoldBooks;
    }

    function fetchInventory() public view returns (ebook[] memory) {
        ebook[] memory myBooks;
        uint32 counter = 0;
        for (uint32 i = 0; i < _tokenId.current(); i++) {
            if (idToEbook[i].owner == msg.sender) {
                myBooks[counter] = idToEbook[i];
                counter++;
            }
        }
        return myBooks;
    }

    function fetchMyListings() public view returns (ebook[] memory) {
        ebook[] memory myListedBooks;
        uint32 counter = 0;
        for (uint32 i = 0; i < _tokenId.current(); i++) {
            if (idToEbook[i].creator == msg.sender) {
                myListedBooks[counter] = idToEbook[i];
                counter++;
            }
        }
        return myListedBooks;
    }
}