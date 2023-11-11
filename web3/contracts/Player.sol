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
 * Contract with developed modifiers for access restriction. 
 * Only the creator can handle (call functions of this contract) this contract which should be the ContractsHandler.
 */ 
import {AccessRestriction} from "./Modifiers.sol";


/**
 * Library with common functions
 */ 
import {Utils} from "./Utils.sol";

/**
 * This is the Contract for the Player. Serves also to interface with RPS contracts
 */
contract Player is AccessRestriction {
    
    // Library Utils
    using Utils for *;
    bytes32 private getGameNameHash;
    
    string private playerName; ///  playerName player name; set by player during registration
    string[3] private gamesNames; /// gamesNames Array of games
    uint private activeGamesCount; /// activeGamesCount Number of active games in which the player is involved
    uint private walletIndex; /// walletIndex Index that corresponds to the players key in the walletMap mapping
    
    /** @dev This contract constructor
     *  @param _name The player's name
     *  @param _index The player's wallet index
     */  
    constructor(string memory _name, uint _index) {
        playerName = _name;
        walletIndex = _index;
    }
        
    /** @dev Handler calls for creating the RPS contract
     *  @param _c The move
     *  @param _salt The crypto random salt generated for hashing
     *  @param _j2 challenged player virtual address
     *  This is not the wallet address which is kept inside the game structure (stored in the handler).
     *  Analogously, msg.sender will be this contract's address.
     *  @return The RPS contract which will be stored by the handler in the corresponding game structure.
     */  
    function createGame(uint8 _c, uint256 _salt, address _j2) public payable accessRestricted returns (RPS) {
        Hasher hasherContract = new Hasher();
        bytes32 _c1Hash = hasherContract.hash(_c, _salt);
        return new RPS(_c1Hash, _j2);
    }

    /** @dev Handler calls for submiting j2 move to the RPS contract
     *  @param gameContract The RPS contract from which the play function is to be called.
     *  @param _c2 The move
     *  Once again, msg.sender will be this contract's address, which in this case corresponds to the virtual address for j2.
     */  
    function play(RPS gameContract, RPS.Move _c2) public payable accessRestricted {
        gameContract.play(_c2);
    }

    /** @dev Handler calls for revealing j1 move by the RPS contract
     *  @param gameContract The RPS contract from which the solve function is to be called.
     *  @param _c1 j1's original move
     *  @param _salt The crypto random salt originally generated for hashing
     *  msg.sender will be this contract's address, which in this case corresponds to the virtual address for j1.
     */  
    function solve(RPS gameContract, RPS.Move _c1, uint256 _salt) public accessRestricted {
        gameContract.solve(_c1, _salt);
    }

    /** @dev Handler calls for time out j1
     *  @param gameContract The RPS contract from which the j1Timeout function is to be called.
     *  msg.sender will be this contract's address, which in this case corresponds to the virtual address for j2.
     */  
    function j1Timeout(RPS gameContract) public accessRestricted {
        gameContract.j1Timeout();
    }

    /** @dev Handler calls for time out j2
     *  @param gameContract The RPS contract from which the j2Timeout function is to be called.
     *  msg.sender will be this contract's address, which in this case corresponds to the virtual address for j1.
     */ 
    function j2Timeout(RPS gameContract) public accessRestricted {
        gameContract.j2Timeout();
    }

    /** @dev Handler calls for freeing storage, allowing the player to create new games (each player can create three simultaneous games maximum). 
     *  The array gamesNames in this contract is updated such that the last element is switched by the game which will be ended.
     *  This is done after calling solve, j1Timeout or j2Timeout, which are the cases in which the game is terminated.
     *  @param hashedGameName The hashed gameName to be finalized 
     */ 
    function deleteGame(bytes32 hashedGameName) public accessRestricted {
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

    /** @dev Handler calls for getting the player name
     *
     */ 
    function getPlayerName() public view accessRestricted returns (string memory) {
        return playerName;
    }
    
    /** @dev Handler calls for getting the games names and sending them back to the client
     *
     */ 
    function getGamesPlayer() public view accessRestricted returns (string memory, string memory, string memory) {
        return (gamesNames[0], gamesNames[1], gamesNames[2]);
    }

    /** @dev Handler calls for getting the games count
     *
     */ 
    function getActiveGamesCount() public view accessRestricted returns (uint) {
        return activeGamesCount;
    }

    /** @dev Handler calls for getting the wallet index of this player
     *
     */ 
    function getWalletIndex() public view accessRestricted returns (uint) {
        return walletIndex;
    }

    /** @dev Handler calls for setting the games name just created
     *  @param _gameName The game name to be stored
     */ 
    function setGameName(string memory _gameName) accessRestricted {
        gamesNames[activeGamesCount] = _gameName;
        activeGamesCount = activeGamesCount + 1;
    }

    /** @dev Handler calls for updating the wallet index of this player. This is done after a player is removed from the dapp
     *  @param _index The new index
     */ 
    function setWalletIndex(uint _index) public accessRestricted {
        walletIndex = _index;
    }
}
