//SPDX-License-Identifier: MIT

pragma solidity ^0.4.26;

library Utils {

    function getGameNameHash(string memory _gameName) public pure returns (bytes32) {
        return keccak256(abi.encode(_gameName));
    }

}
