// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.23;

/////////////////////////////////////////////////////
// Dependencies
/////////////////////////////////////////////////////
// We will be utilizing the Locksmith Key Managemenet system for cross-contract permissions
import "lib/locksmith-core/src/Locksmith.sol";

/////////////////////////////////////////////////////
// Eigenaut Keys 
/////////////////////////////////////////////////////
contract EigenautKeys is Locksmith {
    /**
     * name
     *
     * This is the name of the ERC1155 collection.
     */
    function name() external virtual override pure returns (string memory) {
        return "Eigenauts Governance Keys";
    }
}
