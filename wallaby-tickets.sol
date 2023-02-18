pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WallabyTickets is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private currentId;

    bool[] public events = [false];  // list of active status
    address[] public eventManagers = [msg.sender];
    uint256[] public totalTickets = [100];
    uint256[] public availableTickets = [100];
    uint256 public mintPrice = 0;

    mapping(uint256 => mapping(address => bool)) public usages;
    mapping(uint256 => mapping(address => uint256[])) holders;

    constructor() ERC721("Wallaby Ticket", "TICK") {
        currentId.increment();
    }

    function doEvent() public returns(uint256) {
        events.push(true);
        eventManagers.push(msg.sender);
        totalTickets.push(100);
        availableTickets.push(100);
        return events.length;
    }

    function finishEvent(uint256 eventId) public {
        require(eventManagers[eventId] == msg.sender, "Can be called only by manager");
        events[eventId] = false;
    }

    function buyTicket(uint256 eventId) public payable {
        require(availableTickets[eventId] > 0, "Not enough tickets");
        require(msg.value >= mintPrice, "Not enough ETH!");
        require(events[eventId], "Tickets are not on sale!");

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "Wallaby Tickets #',
                        Strings.toString(currentId.current()),
                        '", "description": "Powered by Wallaby Team", ',
                        '"traits": [{ "trait_type": "Used", "value": "false" }, { "trait_type": "Purchased", "value": "true" }], ',
                        '"image": "https://gateway.pinata.cloud/ipfs/QmV2tMPTdXbsg2ezbYPMA2nR7UHEDEVhZLKqPDmXkE2qtD" }'
                    )
                )
            )
        );

        string memory tokenURI = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        _safeMint(msg.sender, currentId.current());
        _setTokenURI(currentId.current(), tokenURI);
 
        holders[eventId][msg.sender].push(currentId.current());
        currentId.increment();
        availableTickets[eventId] = availableTickets[eventId] - 1;
    }

    function useTicket(address addy, uint256 eventId) public {
        usages[eventId][addy] = true;
        uint256 tokenId = holders[eventId][addy][0];

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "Wallaby Tickets #',
                        Strings.toString(tokenId),
                        '", "description": "Powered by Wallaby Team", ',
                        '"traits": [{ "trait_type": "Used", "value": "true" }, { "trait_type": "Purchased", "value": "true" }], ',
                        '"image": "https://gateway.pinata.cloud/ipfs/QmV2tMPTdXbsg2ezbYPMA2nR7UHEDEVhZLKqPDmXkE2qtD" }'
                    )
                )
            )
        );

        string memory tokenURI = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        _setTokenURI(tokenId, tokenURI);
    }

    function availableTicketCount(uint256 eventId) public view returns (uint256) {
        return availableTickets[eventId];
    }

    function totalTicketCount(uint256 eventId) public view returns (uint256) {
        return totalTickets[eventId];
    }

    function confirmOwnership(address addy, uint256 eventId) public view returns (bool) {
        return holders[eventId][addy].length > 0;
    }
}
