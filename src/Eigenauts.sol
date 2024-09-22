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

// The core interface for interacting with the Eigenaut population.
import "src/interfaces/IEigenauts.sol";

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
// governing rites. Other functions like badge management, game participation,
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
contract Eigenauts is IEigenauts, Initializable, ERC721Upgradeable, UUPSUpgradeable {
    /////////////////////////////////////////////////
    // Token Storage 
    /////////////////////////////////////////////////
    uint256                     public  population;     // The total supply of Eigenauts minted
    mapping(uint256 => address) private _delegations;   // The delegated address for each eigenaut
    mapping(uint256 => string)  private _metadata;      // Token ID => metadataURI
     
    /////////////////////////////////////////////////
    // Access Control 
    /////////////////////////////////////////////////
    address private immutable _deployer;  // Ensures that only the deployer can call genesis
    address private           _locksmith; // Address of the master locksmith (satisfies IEigenauts)
    
    // These values are set at Eigenaut genesis time, and shouldn't change. 
    uint256 public ROOT_KEY;            // priviledge escalation for the entire system
    uint256 public MAINTAINER_KEY;      // upgrade permission on this contract
    uint256 public MINTER_KEY;          // key used for minting eigenauts 

    /**
     * onlyKeyHolder
     *
     * Access control modifer to ensure proper role governance
     * when manging the collection.
     *
     * This specific implementation allows for root key privledge escalation.
     * Presumably a root key could mint the proper key to themselves so this
     * is more of an ergonomic choice than it is a security trade off.
     *
     * @param keyId The Key that the message sender must hold lest the call revert.
     */ 
    modifier onlyKeyHolder(uint256 keyId) {
        require(ILocksmith(_locksmith).hasKeyOrRoot(msg.sender, keyId), 'REQUIRED_KEY_MISSING');
        _;
    }

    /**
     * onlyEigenautHolder
     *
     * Access control modifer to ensure the message sender
     * actually holds the eigenaut that is required for the action.
     *
     * @param eigenautId the id of the ERC721 token the message sender must hold
     */
    modifier onlyEigenautHolder(uint256 eigenautId) {
        require(msg.sender == this.ownerOf(eigenautId), 'EIGENAUT_MISSING');
        _;
    }
    /////////////////////////////////////////////////
    // Deployments and Initialization 
    /////////////////////////////////////////////////

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _deployer = msg.sender;  // make sure we know who the deployer is
        _disableInitializers();
    }

    /**
     * _authorizeUpgrade (internal) 
     *
     * This function is only called by someone holding a maintenance key, and would
     * be considered a developer of the project.
     *
     * If this function doesn't revert, the upgrade is considered authorized.
     * This function will revert if the message sender does not hold the mainenance key.
     */
    function _authorizeUpgrade(address) internal override onlyKeyHolder(MAINTAINER_KEY) {}
    
    /////////////////////////////////////////////////
    // Introspection 
    /////////////////////////////////////////////////

    /**
     * getLocksmith 
     *
     * @return the assigned governance locksmith that was set at genesis.
     */ 
    function getLocksmith() external view returns (address) {
        return _locksmith;
    }

    /**
     * tokenURI
     *
     * We are overriding this because we want a specific one for each token
     * that isn't always derived the same way. We are also skipping the URIStorage
     * extension because this is way less overhead for the same outcome.
     *
     * @param tokenId the token ID you want the metadataURI for
     * @return the string of the metadata URI for that token, or blank likely if the token is invalid.
     */
    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        return _metadata[tokenId]; 
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
    
    /////////////////////////////////////////////////
    // Eigenaut Interface 
    /////////////////////////////////////////////////

    /**
     * genesis
     *
     * This is the initializer for the upgradeable contract.
     *
     * This function is only designed to be called once,
     * and it can only be called by the deployer. In general,
     * this function should be called in the same transaction
     * as the deployment as best practice.
     *
     * The deployer provides an initial locksmith and list of governance roles,
     * which is limited to system owners, maintainers, minters for now. 
     *
     * The locksmith assigned at genesis cannot be changed.
     *
     * For each root key holder provided, they will be minted an identical
     * ERC1155 token. This gives them full unilateral
     * governance power over who holds what keys, and defines their
     * transferrability. When fully decentralized these keys will be burned
     * or locked into immutable or governed agent contracts.
     *
     * For each maintainer key holder provided, they will be minted an
     * identical ERC1155 token. This gives them unilateral
     * control over upgrading the core Eigenaut contract, or making it immutable.
     * 
     * For each minter key holder provided, they will be minted an
     * identical ERC1155 token. This gives them unilateral
     * control over adding Eigenauts to the population. When fully decentralized
     * these keys will be locked into immutable or governed agent contracts.
     * While it is possible to burn all the root keys and minter keys effectively
     * locking population, this would be a governed decision by a single root
     * key holder.
     * 
     * This method reverts if:
     * - The caller is not the deployer
     * - Genesis function has already been executed once successfully.
     *
     * @param locksmith      the locksmith used for governance keys
     * @param maintenanceKey the key required to be able to upgrade this contract
     * @param minterKey      the key required to be able to mint eigenauts 
     */ 
    function genesis(address locksmith, uint256 maintenanceKey, uint256 minterKey) initializer external {
        // ensure only the deployer can call this
        require(msg.sender == _deployer, 'NOT_DEPLOYER');

        // this is the reference that will be used when determining 
        // if we trust a message caller
        _locksmith = locksmith;

        // genesis acts as the contract's initializer,
        // so we need to make sure to do this first. 
         __ERC721_init("Eigenauts", "NAUT");
        __UUPSUpgradeable_init();

        // set the governance requirements
        MAINTAINER_KEY = maintenanceKey;
        MINTER_KEY = minterKey;

        // the genesis event emits all of the immutable data
        // for this contract, which for now includes the key
        // permissions
        emit EigenautGenesis(msg.sender, _locksmith, MAINTAINER_KEY, MINTER_KEY);
    }
    
    /**
     * createEigenaut
     *
     * Only message callers who are holding the minter key (id: 2), are capable
     * of minting new Eigenauts. When this call is done, the recipient will receive
     * an Eigenaut ERC721 NFT with an auto-incremented ID.
     *
     * The metadata structure will be defined in the Eigenaut documentation. Please
     * Check accompanying example file in the repository (assets/eigenaut.json) for
     * a fully documented schema.
     *
     * This method will revert if:
     * - The message sender is not holding the minter key. 
     *
     * @param eigenautURI This metadata URI must resolve to a properly formatted metadata JSON.
     * @param recipient   address to receive the newly minted ERC721. Must be capable of receiving it.
     */ 
    function createEigenaut(string calldata eigenautURI, address recipient) onlyKeyHolder(MINTER_KEY) external {
        // store the metadata uri
        _metadata[population] = eigenautURI; 

        // we are going to emit the event here to prevent re-entrancy
        // from corrupting the population count in events. This log
        // is only available if the transaction completes, so this
        // is safe. It is a design decision to enable safe re-entrancy
        // here instead of prevent it with more gas/code
        emit EigenautCreated(msg.sender, MINTER_KEY, population, _metadata[population], recipient);  
        
        // mint the token and increment the population couner
        // we are sending the NFT to the receiver here so we need
        // to ensure this is the last thing that's gunna happen
        _mint(recipient, population++);
    }

    /**
     * setEigenautDelegate
     *
     * For all the cool things we can do, we want to protect our Eigenauts. Built
     * right in is the ability to delegate your Eigenaut to a safer, hotter wallet.
     *
     * Only the Eigenaut holder can call this method to set their own Eigenaut delegate
     * address. Delegated address cannot re-delegate. Only one delegate can exist and
     * calling this in succession with different addresses will revoke any previous
     * delegation.
     *
     * This method reverts if:
     * - The message sender is not holding the Eigenaut with the provided ID.
     *
     * @param eigenautId the id of the NFT you want to provide a delegate for.
     * @param delegate   the address that can potentially act on behalf of a cold storage Eigenaut.
     */
    function setEigenautDelegate(uint256 eigenautId, address delegate) onlyEigenautHolder(eigenautId) external {
        _delegations[eigenautId] = delegate;
        emit EigenautDelegation(msg.sender, eigenautId, delegate);
    }

    /**
     * getEigenautDelegate
     *
     * Return the delegated address (or 0x0), for a provided eigenaut ID.
     * This is useful for other applications that want to enable secure token
     * gating on their precious eigenaut.
     *
     * @param  eigenautId the token ID to inspect the delegate of
     * @return the delegated address as set by the holder or 0x0
     */ 
    function getEigenautDelegate(uint256 eigenautId) external view returns (address) {
        return _delegations[eigenautId];
    }
}
