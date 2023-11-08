//SPDX-License-Identifier: MIT

pragma solidity ^0.4.26;

import {Hasher, RPS} from "./RPS.sol";

contract ContractsHandler {
    // Events
    event NewPlayer(address indexed owner, string name, uint256 index);
    event NewGame(address indexed player1, address indexed player2, string gameName);
    event SecondPlayerMoved(address indexed player1, address indexed player2, string gameName);
    event FirstPlayerRevealed(address indexed player1, address indexed player2, string gameName, address indexed winner);
    event J1Timeout(address indexed player1, address indexed player2, string gameName);
    event J2Timeout(address indexed player1, address indexed player2, string gameName);
    
    /// @dev Player struct to store player info
    struct Player {
        VirtualPlayer vp;
        address playerAddress; /// @param playerAddress player wallet address
        string playerName; /// @param playerName player name; set by player during registration
        string[3] gamesNames; /// @param gamesNames Array of games
        uint activeGamesCount; /// @param activeGamesCount Number of active games in which the player is involved
    }

    /// @dev Game struct to store game info
    struct Game {
        RPS gameContract; /// @param gameContract the contract of this game
        string name; /// @param name game name; set by player who creates game
        address p1Address; /// @param p1Address player 1 address; set by virtual player who creates game
        address p2Address; /// @param p2Address player 2 address; set by virtual player who creates game
        uint256 stake; /// @param stake Stores a copy of the original stake
    }

    mapping(address => uint256) private playerInfo; // Mapping of player addresses to player index in the players array
    mapping(bytes32 => uint256) private gameInfo; // Mapping of game names to game index in the games array
    mapping(bytes32 => Game) private gameMap; // Mapping of game names to game index in the games array
    
    Player[4] private players; // Array of players
    Game[6] private games; // Array of games
    uint public playersLen;
    uint public gamesLen;
    

    function isPlayer(address addr) public view returns (bool) {
        if (playerInfo[addr] == 0) {
            return false;
        } else {
            return true;
        }
    }

    function getPlayer(address addr) internal view returns (Player) {
        require(isPlayer(addr), "Player doesn't exist!");
        return players[playerInfo[addr]-1];
    }

    function isGame(string memory _name) public view returns (bool) {
        if(gameInfo[getGameNameHash(_name)] == 0) {
            return false;
        } else {
            return true;
        }
    }

    function getGame(string memory _name) internal returns (Game) {
        require(isGame(_name), "Game doesn't exist!");
        return games[gameInfo[getGameNameHash(_name)]-1];
    }

    
    function getGamePlayer(uint8 playerNumber, string memory _gameName) internal returns (Player) {
        require((playerNumber==1 || playerNumber==2), "Bad request!");
        Game memory game = getGame(_gameName);
        address playerAddress = game.p1Address;
        if (playerNumber==2) {
            playerAddress = game.p2Address;
        }
        return players[playerInfo[playerAddress]-1];
    }
    
    function getGameContract(string memory _gameName) internal view returns (RPS) {
        return getGame(_gameName).gameContract;
    }

    function isGameIncomplete(string memory _gameName) internal view returns (bool) {
        RPS gameContract = getGameContract(_gameName);
        return gameContract.c2()==RPS.Move.Null;
    }

    function getGameStake(string memory _gameName) public view returns (uint256) {
        return getGame(_gameName).stake;
    }


    function _deletePlayer(address _playerAddress) internal {
        require(players[playerInfo[_playerAddress]-1].activeGamesCount == 0, "Player has active games");
        /* Removing player from array and mapping */
        uint index = playerInfo[_playerAddress]-1;
        if (index>=0) {
            players[index] = players[playersLen-1];
            playerInfo[players[index].playerAddress] = index + 1;
        }
        delete players[playersLen - 1];
        playersLen = playersLen - 1;
        delete playerInfo[_playerAddress];
    }

    
    function setGameEnded(string memory _gameName) internal {
        bytes32 hashedGameName = getGameNameHash(_gameName);
        address j1Address = games[gameInfo[hashedGameName]-1].p1Address; 
        players[playerInfo[j1Address]-1].activeGamesCount = players[playerInfo[j1Address]-1].activeGamesCount - 1; // Player 1 frees one slot of her available games
        uint indexLast = players[playerInfo[j1Address]-1].activeGamesCount;
        
        if (getGameNameHash(players[playerInfo[j1Address]-1].gamesNames[indexLast]) != hashedGameName) { // If it is not the last game which needs to be set to end, we switch it to the last position
            uint indexDelete;
            if (getGameNameHash(players[playerInfo[j1Address]-1].gamesNames[indexLast-1]) == hashedGameName) {
                indexDelete = indexLast-1;
            } else if (getGameNameHash(players[playerInfo[j1Address]-1].gamesNames[indexLast-2]) == hashedGameName) {
                indexDelete = indexLast - 2;
            }
            players[playerInfo[j1Address]-1].gamesNames[indexDelete] = players[playerInfo[j1Address]-1].gamesNames[indexLast]; // switch
        }
        players[playerInfo[j1Address]-1].gamesNames[players[playerInfo[j1Address]-1].activeGamesCount] = ''; // Resets current game name for player 1

        address j2Address = games[gameInfo[hashedGameName]-1].p2Address; 
        players[playerInfo[j2Address]-1].activeGamesCount = players[playerInfo[j2Address]-1].activeGamesCount - 1; // Player 2 frees one slot of her available games
        indexLast = players[playerInfo[j2Address]-1].activeGamesCount;
        if (getGameNameHash(players[playerInfo[j2Address]-1].gamesNames[indexLast]) != hashedGameName) { // If it is not the last game which needs to be set to end, we switch it to the last position
            if (getGameNameHash(players[playerInfo[j2Address]-1].gamesNames[indexLast-1]) == hashedGameName) {
                indexDelete = indexLast - 1;
            } else if (getGameNameHash(players[playerInfo[j2Address]-1].gamesNames[indexLast-2]) == hashedGameName) {
                indexDelete = indexLast - 2;
            }
            players[playerInfo[j2Address]-1].gamesNames[indexDelete] = players[playerInfo[j2Address]-1].gamesNames[indexLast]; // switch
        }
        players[playerInfo[j2Address]-1].gamesNames[players[playerInfo[j2Address]-1].activeGamesCount] = ''; // Resets current game name for player 2

        /* Removing Game from array and mapping */
        uint index = gameInfo[hashedGameName]-1;
        if (index>=0) {
            games[index] = games[gamesLen-1];
            gameInfo[getGameNameHash(games[index].name)] = index + 1;
        }
        delete games[gamesLen - 1];
        gamesLen = gamesLen - 1;
        delete gameInfo[hashedGameName];
    }

    function j2Timeout(string memory _gameName) public {
        RPS gameContract = getGameContract(_gameName);
        Player memory p1 = getGamePlayer(1, _gameName);
        require((msg.sender==p1.playerAddress), "Requesting player is not the first player of this game!");
        uint256 stake = getGame(_gameName).stake;
        VirtualPlayer vp1 = p1.vp;
        vp1.j2Timeout(gameContract);
        address p1Address = p1.playerAddress;
        p1Address.send(stake);
        address p2Address = getGamePlayer(2, _gameName).playerAddress;
        setGameEnded(_gameName);
        
        if (players[playerInfo[p2Address]-1].activeGamesCount == 0) { // Timedout player is deleted if she has no other ongoing games
            _deletePlayer(p2Address);
        }
        emit J2Timeout(msg.sender, p2Address, _gameName);
    }

    function j1Timeout(string memory _gameName) public {
        RPS gameContract = getGameContract(_gameName);
        Player memory p2 = getGamePlayer(2, _gameName);
        require((msg.sender==p2.playerAddress), "Requesting player is not the second player of this game!");
        uint256 stake = getGame(_gameName).stake;
        VirtualPlayer vp2 = p2.vp;
        vp2.j1Timeout(gameContract);
        address p2Address = p2.playerAddress;
        p2Address.send(2*stake);
        address p1Address = getGamePlayer(1, _gameName).playerAddress;
        setGameEnded(_gameName);
        
        if (players[playerInfo[p1Address]-1].activeGamesCount == 0) { // Timedout player is deleted if she has no other ongoing games
            _deletePlayer(p1Address);
        }
        emit J1Timeout(p1Address, p2Address, _gameName);
    }

    function getGameTimeData(string memory _gameName) public view returns (uint256, uint256) {
        RPS gameContract = getGameContract(_gameName);
        return (gameContract.lastAction(), gameContract.TIMEOUT());
    }

    
    function solve(string memory _gameName, RPS.Move _c1, uint256 _salt) public {
        RPS gameContract = getGameContract(_gameName);
        Player memory p1 = getGamePlayer(1, _gameName);
        require((msg.sender==p1.playerAddress), "Requesting player is not the first player of this game!");
        
        uint256 stake = getGame(_gameName).stake;
                
        VirtualPlayer vp1 = p1.vp;
        vp1.solve(gameContract, _c1, _salt);
        address p2Address = getGamePlayer(2, _gameName).playerAddress;

        
        /* --------- Pays back accordingly to real players (RPS payed back to virtual ones) -------------- */
        RPS.Move c2 = gameContract.c2();
        bool p1Wins = gameContract.win(_c1, c2);
        bool p2Wins = gameContract.win(c2, _c1);
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
        Game memory game = getGame(_gameName);
        Player memory p2 = getGamePlayer(2, _gameName);
        require((msg.sender==p2.playerAddress), "Requesting player is not the second player of this game!");
        VirtualPlayer vp2 = p2.vp;
        vp2.play(game.gameContract, _c2);
        address p1Address = getGamePlayer(1, _gameName).playerAddress;
        emit SecondPlayerMoved(p1Address, msg.sender, _gameName);
    }

    function getGameData(string memory _gameName) public view returns (string memory, address, string memory, address, bool) {
        Player memory p1 = getGamePlayer(1, _gameName);
        Player memory p2 = getGamePlayer(2, _gameName);
        return (p1.playerName, p1.playerAddress, p2.playerName, p2.playerAddress, isGameIncomplete(_gameName));
    }

    function getPlayerNumber(uint _index) public view returns (string memory, address){
        require((0<=_index) && (_index<playersLen), "Bad request! Index out of boundaries.");
        return (players[_index].playerName, players[_index].playerAddress);
    }

    function getGamesPlayer() public view returns (string memory, string memory, string memory){
        string[3] memory gamesNames = getPlayer(msg.sender).gamesNames;
        return (gamesNames[0], gamesNames[1], gamesNames[2]);
    }

    function createPlayer(string memory _name) public {
        require(playersLen<4, "Too many registered players. Please come back later!");
        require(!isPlayer(msg.sender), "Player already registered"); // Require that player is not already registered
        string[3] memory gamesNames = ['','',''];
        players[playersLen] = Player(new VirtualPlayer(), msg.sender, _name, gamesNames, 0); // Adds player to players array
        playersLen = playersLen + 1;
        playerInfo[msg.sender] = playersLen; // Creates player info mapping
        emit NewPlayer(msg.sender, _name, playerInfo[msg.sender]); // Triggers event NewPlayer with sender's address, name, and index in the players array
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

        Player memory p1 = getPlayer(msg.sender);
        require(p1.activeGamesCount < 3, "Player has reached his maximum number of active games"); // Requires three games per player maximum
        
        Player memory p2 = getPlayer(_j2Address);
        require(p2.activeGamesCount < 3, "Player has reached his maximum number of active games"); // Requires three games per player maximum

        address _j2 = address(p2.vp);

        Hasher hasherContract = new Hasher();
        bytes32 _c1Hash = hasherContract.hash(_c, _salt);

        RPS newGameContract = p1.vp.createGame(_c1Hash, _j2);
        
        string memory _nameGame = getUniqueGameName(_name);
        games[gamesLen] = Game(newGameContract, _nameGame, msg.sender, _j2Address, msg.value);
        gamesLen = gamesLen + 1;
        gameInfo[getGameNameHash(_nameGame)] = gamesLen; // Creates game info mapping
        
        players[playerInfo[msg.sender]-1].gamesNames[p1.activeGamesCount] = _nameGame;
        players[playerInfo[_j2Address]-1].gamesNames[p2.activeGamesCount] = _nameGame;

        players[playerInfo[msg.sender]-1].activeGamesCount = p1.activeGamesCount + 1;
        players[playerInfo[_j2Address]-1].activeGamesCount = p2.activeGamesCount + 1;
                
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
