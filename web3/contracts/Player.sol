//SPDX-License-Identifier: MIT

/**
 *  @title Rock Paper Scissors Lizard Spock - Player's Contract to be registered to the dapp and to be able for calling RPS contract authored by Clément Lesaege.
 *  @author Martin Moguillansky - <martin.moguillansky@gmail.com>
 */
pragma solidity ^0.4.26;

/*
 * RPS contract authored by Clément Lesaege.
 */ 
import {Hasher, RPS} from "./RPS.sol";

/**
 * Library with common functions
 */ 
import {Utils} from "./Utils.sol";

/**
 * This is the Contract for the Player. Serves also to interface with RPS contracts
 */
contract Player {
    
    // Library Utils
    using Utils for *;
    bytes32 internal getGameNameHash;
    
    string public playerName; ///  playerName player name; set by player during registration
    string[3] public gamesNames; /// gamesNames Array of games
    uint public activeGamesCount; /// activeGamesCount Number of active games in which the player is involved
    uint public walletIndex; /// walletIndex Index that corresponds to the players key in the walletMap mapping
    
    constructor(string memory _name, uint _index) {
        playerName = _name;
        walletIndex = _index;
    }
    
    function createGame(uint8 _c, uint256 _salt, address _j2) public payable returns (RPS) {
        Hasher hasherContract = new Hasher();
        bytes32 _c1Hash = hasherContract.hash(_c, _salt);
        return new RPS(_c1Hash, _j2);
    }

    function play(RPS gameContract, RPS.Move _c2) public payable {
        gameContract.play(_c2);
    }

    function solve(RPS gameContract, RPS.Move _c1, uint256 _salt) public {
        gameContract.solve(_c1, _salt);
    }

    function j1Timeout(RPS gameContract) public {
        gameContract.j1Timeout();
    }

    function j2Timeout(RPS gameContract) public {
        gameContract.j2Timeout();
    }

    function deleteGame(bytes32 hashedGameName) public {
        activeGamesCount = activeGamesCount - 1; // Player frees one slot of her available games
        uint indexLast = activeGamesCount;
        
        if (Utils.getGameNameHash(gamesNames[indexLast]) != hashedGameName) { // If it is not the last game which needs to be set to end, we switch it to the last position
            uint indexDelete;
            if (Utils.getGameNameHash(gamesNames[indexLast-1]) == hashedGameName) {
                indexDelete = indexLast-1;
            } else if (Utils.getGameNameHash(gamesNames[indexLast-2]) == hashedGameName) {
                indexDelete = indexLast - 2;
            }
            gamesNames[indexDelete] = gamesNames[indexLast]; // switch
        }
        gamesNames[activeGamesCount] = ""; // Resets current game name for player 1

    }

    function getGamesPlayer() public view returns (string memory, string memory, string memory){
        return (gamesNames[0], gamesNames[1], gamesNames[2]);
    }

    function setGameName(string memory _gameName) {
        gamesNames[activeGamesCount] = _gameName;
        activeGamesCount = activeGamesCount + 1;
    }

    function setWalletIndex(uint _index) public {
        walletIndex = _index;
    }
}
