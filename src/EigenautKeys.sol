// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.23;

/////////////////////////////////////////////////////
// Dependencies
/////////////////////////////////////////////////////
// We will be utilizing the Locksmith Key Managemenet system for cross-contract permissions
import "lib/locksmith-core/src/Locksmith.sol";

/////////////////////////////////////////////////////
// Eigenaut Keys
//
// A private Locksmith instance, with the following special features:
//
// 1) Upon creation creates the "Genesis Set" of Keys used by the system.
// 2) Only the genesis root key holder can create new key rings.
//
// The purpose of this is for ease of initial deployment, as well as ensure
// that only the original trust structure can create new rings or keys on them.
// When safely governed, this prevents spam and griefing attacks on the contract
// state for anyone outside of the Eigenaut Governance structure.
//
// An important note: This contract is not upgradeable and thus the governing
// rules of the root key cannot be easily changed. For example, if the genesis root
// keys are completely burned, no one will be able to create a new key ring.
//
// This can be avoided by locking the key into a governing contract
// and burning the rest of the keys.
/////////////////////////////////////////////////////
contract EigenautKeys is Locksmith {
    /**
     * constructor
     *
     * This contract is immutable and unowned. The URI is blank, as
     * it will be set during key creation, and can be accessed via
     * IERCMetadataURI.
     *
     * Within this constructor we will create the initial genesis state
     * of the governing keys. All of these keys will be sent to the deployer
     * by default, and soulbound.
     */
    constructor() ERC1155('') {
        // create the trust and the root key

        // mint the initial governing roles into the deployer

    }
        
    /**
     * name
     *
     * This is the name of the ERC1155 collection.
     */
    function name() external virtual override pure returns (string memory) {
        return "Eigenauts Governance Keys";
    }
}
