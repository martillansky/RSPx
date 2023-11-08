//SPDX-License-Identifier: MIT

pragma solidity ^0.4.26;

import {Hasher, RPS} from "./RPS.sol";

contract ContractsHandler {
    // Events
    event NewPlayer(address indexed owner, string name);
    event NewGame(address indexed player1, address indexed player2, string gameName);
    event SecondPlayerMoved(address indexed player1, address indexed player2, string gameName);
    event FirstPlayerRevealed(address indexed player1, address indexed player2, string gameName, address indexed winner);
    event J1Timeout(address indexed player1, address indexed player2, string gameName);
    event J2Timeout(address indexed player1, address indexed player2, string gameName);
    
    /// @dev Player struct to store player info
    struct Player {
        VirtualPlayer vp;
        string playerName; /// @param playerName player name; set by player during registration
        string[3] gamesNames; /// @param gamesNames Array of games
        uint activeGamesCount; /// @param activeGamesCount Number of active games in which the player is involved
        uint walletIndex; /// @param walletIndex Index that corresponds to the playes key in the walletMap mapping
    }

    /// @dev Game struct to store game info
    struct Game {
        RPS gameContract; /// @param gameContract the contract of this game
        string name; /// @param name game name; set by player who creates game
        address p1Address; /// @param p1Address player 1 address; set by virtual player who creates game
        address p2Address; /// @param p2Address player 2 address; set by virtual player who creates game
        uint256 stake; /// @param stake Stores a copy of the original stake
    }

    mapping(address => Player) private playerMap; // Mapping of player addresses to players
    mapping(uint => address) private walletMap; // Mapping of player number to player addresses
    mapping(bytes32 => Game) private gameMap; // Mapping of hashed game names to games
    
    uint public playersLen;
    uint public gamesLen;
    

    function isPlayer(address addr) public view returns (bool) {
        return (bytes(playerMap[addr].playerName).length > 0);
    }

    function isGame(string memory _name) public view returns (bool) {
        bytes32 _hashedName = getGameNameHash(_name);
        return(getGameNameHash(gameMap[_hashedName].name) == _hashedName);
    }

    function isGameIncomplete(string memory _gameName) internal view returns (bool) {
        return gameMap[getGameNameHash(_gameName)].gameContract.c2()==RPS.Move.Null;
    }

    function getGameStake(string memory _gameName) public view returns (uint256) {
        require(isGame(_gameName), "Game doesn't exist!"); // Requires game
        return gameMap[getGameNameHash(_gameName)].stake;
    }

    function _deletePlayer(address _playerAddress) internal {
        require(playerMap[_playerAddress].activeGamesCount == 0, "Player has active games");
        delete walletMap[playerMap[_playerAddress].walletIndex];
        delete playerMap[_playerAddress];
        playersLen = playersLen - 1;
    }

    
    function setGameEnded(string memory _gameName) internal {
        bytes32 hashedGameName = getGameNameHash(_gameName);

        address j1Address = gameMap[hashedGameName].p1Address; 
        playerMap[j1Address].activeGamesCount = playerMap[j1Address].activeGamesCount - 1; // Player 1 frees one slot of her available games
        uint indexLast = playerMap[j1Address].activeGamesCount;
        
        if (getGameNameHash(playerMap[j1Address].gamesNames[indexLast]) != hashedGameName) { // If it is not the last game which needs to be set to end, we switch it to the last position
            uint indexDelete;
            if (getGameNameHash(playerMap[j1Address].gamesNames[indexLast-1]) == hashedGameName) {
                indexDelete = indexLast-1;
            } else if (getGameNameHash(playerMap[j1Address].gamesNames[indexLast-2]) == hashedGameName) {
                indexDelete = indexLast - 2;
            }
            playerMap[j1Address].gamesNames[indexDelete] = playerMap[j1Address].gamesNames[indexLast]; // switch
        }
        playerMap[j1Address].gamesNames[playerMap[j1Address].activeGamesCount] = ''; // Resets current game name for player 1

        address j2Address = gameMap[hashedGameName].p2Address; 
        playerMap[j2Address].activeGamesCount = playerMap[j2Address].activeGamesCount - 1; // Player 2 frees one slot of her available games
        indexLast = playerMap[j2Address].activeGamesCount;
        if (getGameNameHash(playerMap[j2Address].gamesNames[indexLast]) != hashedGameName) { // If it is not the last game which needs to be set to end, we switch it to the last position
            if (getGameNameHash(playerMap[j2Address].gamesNames[indexLast-1]) == hashedGameName) {
                indexDelete = indexLast - 1;
            } else if (getGameNameHash(playerMap[j2Address].gamesNames[indexLast-2]) == hashedGameName) {
                indexDelete = indexLast - 2;
            }
            playerMap[j2Address].gamesNames[indexDelete] = playerMap[j2Address].gamesNames[indexLast]; // switch
        }
        playerMap[j2Address].gamesNames[playerMap[j2Address].activeGamesCount] = ''; // Resets current game name for player 2

        /* Removing Game from array and mapping */
        gamesLen = gamesLen - 1;
        delete gameMap[hashedGameName];
    }

    
    function j2Timeout(string memory _gameName) public {
        require(isGame(_gameName), "Game doesn't exist!"); // Requires game
        bytes32 hashedGameName = getGameNameHash(_gameName);
        RPS gameContract = gameMap[hashedGameName].gameContract;
        address p1Address = gameMap[hashedGameName].p1Address;
        require((msg.sender==p1Address), "Requesting player is not the first player of this game!");
        uint256 stake = gameMap[hashedGameName].stake;
        VirtualPlayer vp1 = playerMap[gameMap[hashedGameName].p1Address].vp;
        vp1.j2Timeout(gameContract);
        p1Address.send(stake);
        address p2Address = gameMap[hashedGameName].p2Address;
        
        setGameEnded(_gameName);
        
        if (playerMap[p2Address].activeGamesCount == 0) { // Timedout player is deleted if she has no other ongoing games
            _deletePlayer(p2Address);
        }
        emit J2Timeout(msg.sender, p2Address, _gameName);
    }

    function j1Timeout(string memory _gameName) public {
        require(isGame(_gameName), "Game doesn't exist!"); // Requires game
        bytes32 hashedGameName = getGameNameHash(_gameName);
        RPS gameContract = gameMap[hashedGameName].gameContract;
        address p2Address = gameMap[hashedGameName].p2Address;
        require((msg.sender==p2Address), "Requesting player is not the second player of this game!");
        uint256 stake = gameMap[hashedGameName].stake;
        VirtualPlayer vp2 = playerMap[gameMap[hashedGameName].p2Address].vp;
        vp2.j1Timeout(gameContract);
        p2Address.send(2*stake);
        address p1Address = gameMap[hashedGameName].p1Address;
        setGameEnded(_gameName);
        
        if (playerMap[p1Address].activeGamesCount == 0) { // Timedout player is deleted if she has no other ongoing games
            _deletePlayer(p1Address);
        }
        emit J1Timeout(p1Address, p2Address, _gameName);
    }

    function getGameTimeData(string memory _gameName) public view returns (uint256, uint256) {
        require(isGame(_gameName), "Game doesn't exist!"); // Requires game
        return (gameMap[getGameNameHash(_gameName)].gameContract.lastAction(), gameMap[getGameNameHash(_gameName)].gameContract.TIMEOUT());
    }

    
    function solve(string memory _gameName, RPS.Move _c1, uint256 _salt) public {
        require(isGame(_gameName), "Game doesn't exist!"); // Requires game
        bytes32 hashedGameName = getGameNameHash(_gameName);
        require((msg.sender == gameMap[hashedGameName].p1Address), "Requesting player is not the first player of this game!");
        uint256 stake = gameMap[hashedGameName].stake;
        VirtualPlayer vp1 = playerMap[gameMap[hashedGameName].p1Address].vp;
        vp1.solve(gameMap[hashedGameName].gameContract, _c1, _salt);
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
        setGameEnded(_gameName);
        emit FirstPlayerRevealed(msg.sender, p2Address, _gameName, winner);
    }

    function play(RPS.Move _c2, string memory _gameName) public payable {
        require(isGame(_gameName), "Game doesn't exist!"); // Requires game
        bytes32 hashedGameName = getGameNameHash(_gameName);
        require((msg.sender == gameMap[hashedGameName].p2Address), "Requesting player is not the second player of this game!");
        VirtualPlayer vp2 = playerMap[gameMap[hashedGameName].p2Address].vp;
        vp2.play(gameMap[hashedGameName].gameContract, _c2);
        address p1Address = gameMap[hashedGameName].p1Address;
        emit SecondPlayerMoved(p1Address, msg.sender, _gameName);
    }

    function getGameData(string memory _gameName) public view returns (string memory, address, string memory, address, bool) {
        require(isGame(_gameName), "Game doesn't exist!"); // Requires game
        bytes32 hashedGameName = getGameNameHash(_gameName);
        return (
            playerMap[gameMap[hashedGameName].p1Address].playerName, 
            gameMap[hashedGameName].p1Address, 
            playerMap[gameMap[hashedGameName].p2Address].playerName, 
            gameMap[hashedGameName].p2Address, 
            isGameIncomplete(_gameName)
        );
    }

    function getPlayerNumber(uint _index) public view returns (string memory, address){
        require((0<=_index) && (_index<playersLen), "Bad request! Index out of boundaries.");
        return (playerMap[walletMap[_index]].playerName, walletMap[_index]);
    }

    function getGamesPlayer() public view returns (string memory, string memory, string memory){
        string[3] memory gamesNames = playerMap[msg.sender].gamesNames;
        return (gamesNames[0], gamesNames[1], gamesNames[2]);
    }

    function createPlayer(string memory _name) public {
        require(playersLen<4, "Too many registered players. Please come back later!");
        require(!isPlayer(msg.sender), "Player already registered"); // Require that player is not already registered
        string[3] memory gamesNames = ['','',''];
        playerMap[msg.sender] = Player(new VirtualPlayer(), _name, gamesNames, 0, playersLen); // Adds player to players array
        walletMap[playersLen] = msg.sender;
        playersLen = playersLen + 1;
        emit NewPlayer(msg.sender, _name); // Triggers event NewPlayer with sender's address and name
    }

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

    function getGameNameHash(string memory _gameName) internal returns (bytes32) {
        return keccak256(abi.encode(_gameName));
    }

    function createGame(string memory _name, uint8 _c, uint256 _salt, address _j2Address) public payable {
        require(gamesLen<6, "Too many ongoing games. Please come back later!");
        require(isPlayer(msg.sender), "Player not registered"); // Requires creator as a registered player
        require(isPlayer(_j2Address), "Player not registered"); // Requires a registered second player
        require(msg.value>0); // Require positive stake
        require(_c>0); // A move is necessarily selected.

        require(playerMap[msg.sender].activeGamesCount < 3, "Player has reached his maximum number of active games"); // Requires three games per player maximum
        
        require(playerMap[_j2Address].activeGamesCount < 3, "Player has reached his maximum number of active games"); // Requires three games per player maximum

        address _j2 = address(playerMap[_j2Address].vp);

        Hasher hasherContract = new Hasher();
        bytes32 _c1Hash = hasherContract.hash(_c, _salt);

        RPS newGameContract = playerMap[msg.sender].vp.createGame(_c1Hash, _j2);
        
        string memory _nameGame = getUniqueGameName(_name);
        gameMap[getGameNameHash(_nameGame)] = Game(newGameContract, _nameGame, msg.sender, _j2Address, msg.value);
        gamesLen = gamesLen + 1;
        
        playerMap[msg.sender].gamesNames[playerMap[msg.sender].activeGamesCount] = _nameGame;
        playerMap[_j2Address].gamesNames[playerMap[_j2Address].activeGamesCount] = _nameGame;

        playerMap[msg.sender].activeGamesCount = playerMap[msg.sender].activeGamesCount + 1;
        playerMap[_j2Address].activeGamesCount = playerMap[_j2Address].activeGamesCount + 1;
                
        emit NewGame(msg.sender, _j2Address, _nameGame);
    }
}

contract VirtualPlayer{
    function createGame(bytes32 _c1Hash, address _j2) public payable returns (RPS) {
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
}
