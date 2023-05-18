// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract NFTCollection is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Address for address payable;

    // Counter for the NFT
    Counters.Counter public editionCounter;

    // Collection constants
    uint256 public editionLimit;
    uint256 public price;
    uint256 public openingTime;
    string public codeURI;
    string public detailURI;
    address payable[] public splitAddresses;
    uint256[] public splitPercentages;
    uint256 public royalties;

    // Mapping from counter to owner address for the preminting
    mapping(uint256 => address) public premints;
    // Mapping from counter to seed for the preminting
    mapping(uint256 => bytes32) public premintSeeds;


    /**
     * @dev Emitted when an NFT is preminted by the to user
     */
    event Premint(address indexed to, uint256 indexed counter, bytes32 seed);

    constructor(
        string memory name_, 
        string memory symbol_
        uint256 _editionLimit,
        uint256 _price,
        uint256 _openingTime,
        string memory _codeURI,
        string memory _detailURI,
        address payable[] memory _splitAddresses,
        uint256[] memory _splitPercentages,
        uint256 _royalties
    ) ERC721(name_, symbol_) {
        editionLimit = _editionLimit;
        price = _price;
        openingTime = _openingTime;
        codeURI = _codeURI;
        detailURI = _detailURI;
        splitAddresses = _splitAddresses;
        splitPercentages = _splitPercentages;
        royalties = _royalties;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), tokenId));
    }

    function _randomSeed(uint256 counter) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, counter));
    }

    function premint(address to) public payable {
        require(block.timestamp >= openingTime, "Sale has not started");
        require(msg.value >= price, "Insufficient funds sent");
        require(editionCounter.current() < editionLimit, "Edition limit reached");

        // Create random seed
        bytes32 seed=_randomSeed(editionCounter.current())
        // Save premint
        premints[editionCounter.current()]=to
        premintSeeds[editionCounter.current()]=seed

        emit Premint(to,editionCounter.current(),seed)

        editionCounter.increment();

        for (uint i = 0; i < splitAddresses.length; i++) {
            splitAddresses[i].sendValue(msg.value * splitPercentages[i] / 100);
        }
    }

    /**
     * @dev Returns whether `counter` has been preminted.
     */
    function _isPreminted(uint256 counter) internal view virtual returns (bool) {
        return premints[counter] != address(0);
    }

    /**
     * @dev Mints the definitive NFT ("reveal")
     * 
     * Only the admin can do that (with the correctly generated image and metadata)
     */
    function mint(address to, uint256 counter,string memory ipfsHash) public onlyOwner {
        // Make sure NFT has been preminted
        require(_isPreminted(counter), "The NFT for this counter hasn't been preminted");
        // Mint with the final pointer to the metadata
        _mint(to, ipfsHash);
    }
}

