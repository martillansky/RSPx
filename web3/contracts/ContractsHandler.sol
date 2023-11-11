//SPDX-License-Identifier: MIT


/**
 *  @title Rock Paper Scissors Lizard Spock - Contract Factory for registering players, games and triggering events to the client. 
 *          Modifiers can be applied here. Uses the RPS contract authored by Clément Lesaege.
 *  @author Martin Moguillansky - <martin.moguillansky@gmail.com>
 */

pragma solidity ^0.4.26;

/*
 * RPS contract authored by Clément Lesaege.
 */ 
import {RPS} from "./RPS.sol"; 


/**
 * Player contract for modular purposes. Players need a contract address to use RPS. 
 * This cannot be done directly from this factory since the msg.sender would be always the same,
 * without distinguishing player1 from player2.
 */ 
import {Player} from "./Player.sol"; 

/**
 * Library with common functions
 */ 
import {Utils} from "./Utils.sol";

/**
 * Contracts with developed modifiers for avoiding reentrancy and timestamp manipulation.
 * TimestampFetcher proposes a modifier for controling timestamp manipulation by registering 
 * the current timestamp from the chainlink oracle
 */ 
import {ReEntrancyGuard, TimestampFetcher} from "./Modifiers.sol";


/**
 * This is the Contract handler for the game.
 */
contract ContractsHandler is ReEntrancyGuard, TimestampFetcher {
    
    // Library Utils
    using Utils for *;
    bytes32 internal getGameNameHash;
    

    // Events
    event NewPlayer(address indexed owner, string name);
    event NewGame(address indexed player1, address indexed player2, string gameName);
    event SecondPlayerMoved(address indexed player1, address indexed player2, string gameName);
    event FirstPlayerRevealed(address indexed player1, address indexed player2, string gameName, address indexed winner);
    event J1Timeout(address indexed player1, address indexed player2, string gameName);
    event J2Timeout(address indexed player1, address indexed player2, string gameName);
    
    /// @dev Game struct to store game info
    struct Game {
        RPS gameContract; /// @param gameContract the contract of this game
        string name; /// @param name standing for game name; set by player who creates game
        address p1Address; /// @param p1Address player 1 address; set by virtual player who creates game
        address p2Address; /// @param p2Address player 2 address; set by virtual player who creates game
        uint256 stake; /// @param stake Stores a copy of the original stake
    }

    mapping(address => Player) private playerMap; // Mapping of player addresses to players
    mapping(uint => address) private walletMap; // Mapping of player number to player addresses
    mapping(bytes32 => Game) private gameMap; // Mapping of hashed game names to games
    
    uint public playersLen; // registered players
    uint public gamesLen; // registered games

    uint constant MAX_GAMES_PER_PLAYER = 3;
    uint constant MAX_PLAYERS = 4;
    uint constant MAX_GAMES = 6;


    /** @dev Checks if the player was already registered
     *  @param _addr The wallet address of the player to check
     */ 
    function isPlayer(address _addr) public view returns (bool) {
        return (playerMap[_addr] != address(0x0)); // There is no Player contract for address addr
    }

    /** @dev Checks if the game was already registered
     *  @param _gameName The name of the game to check
     */ 
    function isGame(string memory _gameName) public view returns (bool) {
        bytes32 _hashedName = Utils.getGameNameHash(_gameName);
        
        // Checks if the hash of the name in the structure obtained from the gameMap coincides with the hash of _gameName.
        // The map will always deliver a Game struct so we need to check about the name inside in case it is the empty string,
        // which means that the gameMap has no hash for the given _gameName
        return(Utils.getGameNameHash(gameMap[_hashedName].name) == _hashedName); 
    }

    /** @dev Checks if the current state of the given game has still missing the move of player2
     *  @param _gameName The name of the game to check
     */ 
    function isGameIncomplete(string memory _gameName) internal view noReentrant returns (bool) {
        return gameMap[Utils.getGameNameHash(_gameName)].gameContract.c2()==RPS.Move.Null;
    }

    /** @dev To be used by the client in order to get the stake made by player1 by the time she created the current game
     *  @param _gameName The name of the game
     */ 
    function getGameStake(string memory _gameName) public view returns (uint256) {
        require(isGame(_gameName), "Game doesn't exist!"); // Requires game
        return gameMap[Utils.getGameNameHash(_gameName)].stake;
    }

    /** @dev The register of a player can be removed when she was timed out from a game and she has no pending or ongoing games.
     *  @param _playerAddress The wallet address of the player
     */ 
    function _deletePlayer(address _playerAddress) private {
        require(playerMap[_playerAddress].activeGamesCount() == 0, "Player has active games"); // There should be no ongoing games for the player
        uint pWalletIndex = playerMap[_playerAddress].walletIndex();
        if (pWalletIndex != playersLen-1) { // Switches indexes between player to remove and last player, only if they are different
            playerMap[walletMap[playersLen-1]].setWalletIndex(pWalletIndex); // Updates the index in the last Players contract to the index of the player to be deleted
            walletMap[pWalletIndex] = walletMap[playersLen-1]; //switches the last element
        }
        delete walletMap[playersLen-1]; // Removes the last player from the walletMap
        delete playerMap[_playerAddress]; // Removes the player from the playerMap
        playersLen = playersLen - 1; // Updates the quantity of registered players from playersLen
    }

    /** @dev Finalizes the game
     *  @param _gameName The name of the game
     */ 
    function setGameEnded(string memory _gameName) internal {
        bytes32 hashedGameName = Utils.getGameNameHash(_gameName);

        address j1Address = gameMap[hashedGameName].p1Address; 
        playerMap[j1Address].deleteGame(hashedGameName); // Removes the game from the corresponding array from the Player's contract
        
        address j2Address = gameMap[hashedGameName].p2Address; 
        playerMap[j2Address].deleteGame(hashedGameName); // Removes the game from the corresponding array from the Player's contract

        delete gameMap[hashedGameName]; // Removing Game from mapping
        gamesLen = gamesLen - 1;
    }


    /** @dev j1 asks for j2 to be timed out. No reentrancy and timestamp manipulation are controled through modfiers
     *  @param _gameName The name of the game
     */     
    function j2Timeout(string memory _gameName) public noReentrant /* noTSManipulation */ {
        require(isGame(_gameName), "Game doesn't exist!"); // Requires game to exist
        bytes32 hashedGameName = Utils.getGameNameHash(_gameName);
        address p1Address = gameMap[hashedGameName].p1Address; // Wallet address of j1
        require((msg.sender==p1Address), "Requesting player is not the first player of this game!"); 
        uint256 stake = gameMap[hashedGameName].stake;
        playerMap[gameMap[hashedGameName].p1Address].j2Timeout(gameMap[hashedGameName].gameContract); // The contract Player calls RPS j2Timeout which sends back the stake to this constract handler
        p1Address.send(stake); // The recieved stake is sent back to j1
        address p2Address = gameMap[hashedGameName].p2Address;
        setGameEnded(_gameName); // The game is finalized
        
        if (playerMap[p2Address].activeGamesCount() == 0) { // Timed out player is deleted if she has no other ongoing games
            _deletePlayer(p2Address);
        }
        emit J2Timeout(msg.sender, p2Address, _gameName); // Triggers corresonding event to the client
    }

    /** @dev j2 asks for j1 to be timed out. No reentrancy and timestamp manipulation are controled through modfiers
     *  @param _gameName The name of the game
     */ 
    function j1Timeout(string memory _gameName) public noReentrant /* noTSManipulation */ {
        require(isGame(_gameName), "Game doesn't exist!"); // Requires game to exist
        bytes32 hashedGameName = Utils.getGameNameHash(_gameName);
        address p2Address = gameMap[hashedGameName].p2Address; // Wallet address of j2
        require((msg.sender==p2Address), "Requesting player is not the second player of this game!");
        uint256 stake = gameMap[hashedGameName].stake;
        playerMap[gameMap[hashedGameName].p2Address].j1Timeout(gameMap[hashedGameName].gameContract); // The contract Player calls RPS j1Timeout which sends back the stake of both players to this constract handler
        p2Address.send(2*stake); // The recieved stakes are sent back to j2
        address p1Address = gameMap[hashedGameName].p1Address;
        setGameEnded(_gameName); // The game is finalized
        
        if (playerMap[p1Address].activeGamesCount() == 0) { // Timed out player is deleted if she has no other ongoing games
            _deletePlayer(p1Address);
        }
        emit J1Timeout(p1Address, p2Address, _gameName); // Triggers corresonding event to the client
    }

    /** @dev Clients asks for data to control if a player can require to time out his opponent. No reentrancy controled through modfier
     *  @param _gameName The name of the game
     */ 
    function getGameTimeData(string memory _gameName) public view noReentrant returns (uint256, uint256) {
        require(isGame(_gameName), "Game doesn't exist!"); // Requires game

        // We look for the RPS contract and get the lastAction and the TIMEOUT values
        return (gameMap[Utils.getGameNameHash(_gameName)].gameContract.lastAction(), gameMap[Utils.getGameNameHash(_gameName)].gameContract.TIMEOUT());
    }
    
    /** @dev j1 reveals her move and the game is resumed. No reentrancy and timestamp manipulation are controled through modfiers
     *  @param _gameName The name of the game
     *  @param _c1 The original move of j1 
     *  @param _salt The salt used for the hash when the game was created
     */ 
    function solve(string memory _gameName, RPS.Move _c1, uint256 _salt) public noReentrant /* noTSManipulation */ {
        require(isGame(_gameName), "Game doesn't exist!"); // Requires game
        bytes32 hashedGameName = Utils.getGameNameHash(_gameName);
        require((msg.sender == gameMap[hashedGameName].p1Address), "Requesting player is not the first player of this game!");
        uint256 stake = gameMap[hashedGameName].stake;
        playerMap[gameMap[hashedGameName].p1Address].solve(gameMap[hashedGameName].gameContract, _c1, _salt); // RPS solve is called and this factory receives back the corresponding stakes
        address p2Address = gameMap[hashedGameName].p2Address;
        
        /* --------- Pays back accordingly to real players (RPS payed back to virtual ones) -------------- */
        RPS.Move c2 = gameMap[hashedGameName].gameContract.c2();
        bool p1Wins = gameMap[hashedGameName].gameContract.win(_c1, c2);
        bool p2Wins = gameMap[hashedGameName].gameContract.win(c2, _c1);
        address winner;
        if (p1Wins) {
            msg.sender.send(2*stake);
            winner = msg.sender;
        } else if (p2Wins) {
            p2Address.send(2*stake);
            winner = p2Address;
        } else {
            msg.sender.send(stake);
            p2Address.send(stake);
        }

        setGameEnded(_gameName); // The game is finalized
        emit FirstPlayerRevealed(msg.sender, p2Address, _gameName, winner); // Triggers corresonding event to the client
    }

    /** @dev j2 povides her stake and move for the game. No reentrancy controled through modfier
     *  @param _c2 The original move of j2 
     *  @param _gameName The name of the game
     */ 
    function play(RPS.Move _c2, string memory _gameName) public payable noReentrant {
        require(isGame(_gameName), "Game doesn't exist!"); // Requires game
        bytes32 hashedGameName = Utils.getGameNameHash(_gameName);
        require((msg.sender == gameMap[hashedGameName].p2Address), "Requesting player is not the second player of this game!");
        playerMap[gameMap[hashedGameName].p2Address].play(gameMap[hashedGameName].gameContract, _c2); // The contract of the corresponding Player calls RPS.solve
        address p1Address = gameMap[hashedGameName].p1Address;
        emit SecondPlayerMoved(p1Address, msg.sender, _gameName); // Triggers corresonding event to the client
    }

    /** @dev To be called by the client. Provides the data of the game.     
     *  @param _gameName The name of the game
     *  @return (j1 name, j1 walletAddress, j2 name, j2 walletAddress, a boolean to identify if j2 move is still missing)
     */ 
    function getGameData(string memory _gameName) public view returns (string memory, address, string memory, address, bool) {
        require(isGame(_gameName), "Game doesn't exist!"); // Requires game
        bytes32 hashedGameName = Utils.getGameNameHash(_gameName);
        return (
            playerMap[gameMap[hashedGameName].p1Address].playerName(), 
            gameMap[hashedGameName].p1Address, 
            playerMap[gameMap[hashedGameName].p2Address].playerName(), 
            gameMap[hashedGameName].p2Address, 
            isGameIncomplete(_gameName)
        );
    }

    /** @dev To be called by the client. Provides the data of a player by number (We only allow four players to register to this dapp).
     *  @param _index The nummber of the player required. 
     *  @return (player's name, walletAddress)
     */ 
    function getPlayerNumber(uint _index) public view returns (string memory, address){
        require((0<=_index) && (_index<playersLen), "Bad request! Index out of boundaries.");
        return (playerMap[walletMap[_index]].playerName(), walletMap[_index]);
    }

    /** @dev To be called by the client. 
     *  @return Provides the name of each of the three allowed games for a player to be involved
     */ 
    function getGamesPlayer() public view returns (string memory, string memory, string memory){
        return playerMap[msg.sender].getGamesPlayer();
    }

    /** @dev To be called by the client. Registers a new player to the dapp
     *  @param _name The name of the player
     */ 
    function createPlayer(string memory _name) public {
        require(playersLen < MAX_PLAYERS, "Too many registered players. Please come back later!");
        require(!isPlayer(msg.sender), "Player already registered"); // Require that player is not already registered
        playerMap[msg.sender] = new Player(_name, playersLen); // Adds player to players array
        walletMap[playersLen] = msg.sender;
        playersLen = playersLen + 1;
        emit NewPlayer(msg.sender, _name); // Triggers event NewPlayer with sender's address and name
    }

    /** @dev The required name of a game before its creation needs to be checked. 
     *  If another game with the same name is already registered, the name is slightly modified.
     *  @param _name The required name of the new game
     *  @return A verified unique name
     */ 
    function getUniqueGameName(string memory _name) internal view returns (string) {
        string memory _nameGame = _name;
        if (isGame(_name)) {
            _nameGame = string(abi.encodePacked(_name, "-v2"));
        }
        while (isGame(_nameGame)) {
            _nameGame = string(abi.encodePacked(_nameGame, ".1"));
        }
        return _nameGame;
    }

    /** @dev To be called by the client. Registers a new game to the dapp. No reentrancy is controlled through corresponding modifier
     *  RPS is also invoked (through the Player's contract) to register a new RPS contract for this game with the players stake, move and salt to be hashed.
     *  @param _name the required name for the new game
     *  @param _c j1's move
     *  @param _salt the salt for the hash for creating the RPS contract
     *  @param _j2Address the wallet address of the challenged second player (needs to be registered to the dapp)
     */     
    function createGame(string memory _name, uint8 _c, uint256 _salt, address _j2Address) public payable noReentrant {
        require(gamesLen < MAX_GAMES, "Too many ongoing games. Please come back later!");
        require(isPlayer(msg.sender), "Player not registered"); // Requires creator as a registered player
        require(isPlayer(_j2Address), "Player not registered"); // Requires a registered second player
        require(msg.value>0, "Positive stake is required"); // Require positive stake
        require(_c>0, "Bad request. Choose a move"); // A move is necessarily selected.

        require(playerMap[msg.sender].activeGamesCount() < MAX_GAMES_PER_PLAYER, "Player has reached his maximum number of active games"); // Requires three games per player maximum
        
        require(playerMap[_j2Address].activeGamesCount() < MAX_GAMES_PER_PLAYER, "Player has reached his maximum number of active games"); // Requires three games per player maximum

        address _j2 = address(playerMap[_j2Address]);

        RPS newGameContract = playerMap[msg.sender].createGame(_c, _salt, _j2);
        
        string memory _nameGame = getUniqueGameName(_name);
        gameMap[Utils.getGameNameHash(_nameGame)] = Game(newGameContract, _nameGame, msg.sender, _j2Address, msg.value);
        gamesLen = gamesLen + 1;
        
        playerMap[msg.sender].setGameName(_nameGame);
        playerMap[_j2Address].setGameName(_nameGame);
                
        emit NewGame(msg.sender, _j2Address, _nameGame);
    }
}

