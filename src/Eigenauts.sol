// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.23;

/////////////////////////////////////////////////////
// Dependencies
/////////////////////////////////////////////////////
//  The Eigenaut collectable is a ERC-721 upgradeable token contract 
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// We will be utilizing the Locksmith Key Managemenet system for cross-contract permissions
import "lib/locksmith-core/src/interfaces/ILocksmith.sol";

/////////////////////////////////////////////////////
// Eigenauts
//
// This ERC721 NFT collection is a private collection that is
// designed to build community within the Eigen Layer effort, and
// ultimately, the ecosystem. Eventually this contract will be upgraded
// out of centralized control into a lightweight self-governing system
// of Keys - still mutable but governed by the Eigenaut holders.
//
// The key and NFT system are designed to enable seemless extensions
// of the NFT capabilities, so this contract will mainly focus
// on managing the population of the Eigenaut commmunity, and their
// governing rites.. Other functions like badge management, game participation,
// or other extensions to what the Eigenauts are capable of will
// be delivered as extensible contracts.
//
// The main features of the Eigenaut contracts are:
//
// 1) Seeding the initial population of Eigenauts for genesis.
// 2) Setting governance roles for the community.
// 3) Minting new Eigenauts, and the rules around that.
// 4) Migrating or moving Eigenauts safely to new wallets.
//
/////////////////////////////////////////////////////
contract Eigenauts is Initializable, ERC721Upgradeable, UUPSUpgradeable {
    /////////////////////////////////////////////////
    // STORAGE
    /////////////////////////////////////////////////
    uint256 public population;      // The total supply of Eigenauts minted

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * initialize
     *
     * Because upgradeable contracts don't truly use/have a constructor, all of that logic
     * has moved to initialize(). This contract calls necessary derived constructors to
     * create the proper state, set the name, ticker, and ensure the upgradeable state
     * is correct.
     */
    function initialize() initializer public {
        __ERC721_init("Eigenauts", "NAUT");
        __UUPSUpgradeable_init();
    }

    /**
     * _authorizeUpgrade (internal) 
     *
     * This function is only called by someone holding a maintenance key, and would
     * be considered a developer of the project.
     *
     * @param newImplementation the address of the new implementation logic and storage layout.
     */
    function _authorizeUpgrade(address newImplementation) internal pure override { 
        require(false,'NOT_SUPPORTED');
    }

    /**
     * supportsInterface
     *
     * We want to make sure other programs and recognize how to work with the Eigenaut Contract.
     * The first implementation of this is to ensure its recognized as an upgradeable ERC721 contract.
     *
     * @param interfaceId the four leading bytes of the functon selector as defined by the contract ABI
     * @return true if the method signature is there, false otherwise.
     */ 
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
