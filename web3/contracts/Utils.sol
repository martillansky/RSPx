//SPDX-License-Identifier: MIT

/**
 *  @title Rock Paper Scissors Lizard Spock - Library 
 *  @author Martin Moguillansky - <martin.moguillansky@gmail.com>
 */
pragma solidity ^0.4.26;

library Utils {

    /** @dev This function serves for hashing unique string names to be used as the key of mappings
     *  @param _gameName The name of the game
     *  @return The hashed name of the game to be mapped
     */  
    function getGameNameHash(string memory _gameName) public pure returns (bytes32) {
        return keccak256(abi.encode(_gameName));
    }

}
