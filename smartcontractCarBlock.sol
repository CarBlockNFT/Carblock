// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/utils/Strings.sol";

contract CarNFT is ERC721Enumerable, Ownable { 
    using Counters for Counters.Counter; 
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter; 

    struct Car { 
        string model; 
        uint256 mileage; 
        string[] serviceRecords; 
    } 

    mapping(uint256 => Car) public cars; 
    mapping(address => bool) private mechanics; 

    event NewServiceRecord(uint256 tokenId, string record); 

    constructor() ERC721("CarNFT", "CAR") {} 

    function setMechanic(address mechanic, bool isMechanic) external onlyOwner { 
        mechanics[mechanic] = isMechanic; 
    } 

    function mint(address carOwner, string memory model, uint256 mileage) external { 
        require(mechanics[msg.sender], "Only mechanics can mint NFTs"); 
        _tokenIdCounter.increment(); 
        uint256 newTokenId = _tokenIdCounter.current(); 
        _mint(carOwner, newTokenId); 
        cars[newTokenId] = Car(model, mileage, new string[](0)); 
    } 

    function addServiceRecord(uint256 tokenId, string memory record) external { 
        require(mechanics[msg.sender], "Only mechanics can add records"); 
        cars[tokenId].serviceRecords.push(record); 
        emit NewServiceRecord(tokenId, record); 
    } 

    function getServiceRecordsCount(uint256 tokenId) external view returns (uint256) { 
        return cars[tokenId].serviceRecords.length; 
    } 

    function getServiceRecord(uint256 tokenId, uint256 index) external view returns (string memory) { 
        require(index < cars[tokenId].serviceRecords.length, "Invalid index"); 
        return cars[tokenId].serviceRecords[index]; 
    } 

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) { 
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token"); 
        Car memory car = cars[tokenId]; 

        string memory json = string(abi.encodePacked( 
            '{"model": "', car.model, 
            '", "mileage": ', car.mileage.toString(), 
            ', "serviceRecords": [' 
        )); 
        for (uint256 i = 0; i < car.serviceRecords.length; i++) { 
            json = string(abi.encodePacked(json, 
                '"', car.serviceRecords[i], 
                '"', (i == car.serviceRecords.length - 1) ? '' : ',' 
            )); 
        } 
        json = string(abi.encodePacked(json, ']}')); 

        return string(abi.encodePacked("data:application/json;base64,", encode(json))); 
    } 

   function encode(string memory _data) public pure returns (string memory) {  
    bytes memory _dataBytes = bytes(_data);  
    uint256 dataLength = _dataBytes.length; 
    string memory _base64Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";  
    uint256 _encodedLen = 4 * ((dataLength + 2) / 3);  
    bytes memory _result = new bytes(_encodedLen + 32);  

    assembly {  
        let tablePtr := add(_base64Alphabet, 1)  
        let resultPtr := add(_result, 32)  
        let remainder := mod(dataLength, 3)

        for { let i := 0 } lt(i, dataLength) { i := add(i, 3) } {  
            let input := and(mload(add(_dataBytes, i)), 0xFFFFFF)  
            let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))  
            out := shl(8, out)  
            out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))  
            out := shl(8, out)  
            out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))  
            out := shl(8, out)  
            out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))  
            mstore(add(resultPtr, mul(div(i, 3), 4)), out)  
        }  

        if eq(remainder, 1) { 
            mstore(sub(add(resultPtr, _encodedLen), 2), shl(8, 0x3d3d)) 
        } 
        if eq(remainder, 2) { 
            mstore(sub(add(resultPtr, _encodedLen), 1), 0x3d) 
        } 

        mstore(_result, _encodedLen)  
    }  

    return string(_result);  
}



}
