// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.23;

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
// The main features of the Eigenaut contract is:
//
// 1) Seeding the initial population of Eigenauts for genesis.
// 2) Setting governance roles for the community.
// 3) Minting new Eigenauts.
//
/////////////////////////////////////////////////////
interface IEigenauts {
    /////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////

    /**
     * EigenautGenesis
     *
     * This event fires once when genesis occurs.
     *
     * @param operator       the deployer of the eigenaut contract, essentially
     * @param locksmith      the reference to the locksmith to enforce permissions
     * @param maintenanceKey the key id from the locksmith that is allowed to upgrade the contract
     * @param minterKey      the key id from the locksmith that is allowed to mint keys
     */
    event EigenautGenesis(
        address operator,
        address locksmith,
        uint256 maintenanceKey,
        uint256 minterKey
    );

    /**
     * EigenautCreated
     *
     * This event fires when a new eigenaut is minted.
     *
     * @param operator  the address of the key holder that minted the eigenaut
     * @param minterKey the minter key Id that was authenticated to create the token
     * @param tokenId   the "population ID" of the user.
     * @param tokenUri  the metadata attached to the eigenaut
     * @param receiver  the recipient of the newly minted eigenaut
     */
    event EigenautCreated(
        address operator,
        uint256 minterKey,
        uint256 tokenId,
        string tokenUri,
        address receiver
    );

    /**
     * EigenautDelegation
     *
     * This event fires when an eigenaut delegates their
     * holdership to a hotter wallet for safety.
     *
     * @param operator the holder of the eigenaut that initiated the delegation
     * @param tokenId  the Id of the eigenaut that was being delegated
     * @param delegate the address of the new delegate for the enumerated eigenaut
     */
    event EigenautDelegation(
        address operator,
        uint256 tokenId,
        address delegate
    );

    /////////////////////////////////////////////////
    // Interface 
    /////////////////////////////////////////////////
    
    /**
     * genesis
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
     * Each maintainer key holder has unilateral control over 
     * upgrading the core Eigenaut contract, or making it immutable.
     *
     * Each minter key holder has unilateral control over 
     * adding to the Eigenaut Population and defining metadata. 
     * 
     * This method reverts if:
     * - The caller is not the deployer.
     * - Genesis function has already been executed once successfully.
     * - the keys provided are not validated on the same ring.
     *
     * @param locksmith      the locksmith used for governance keys
     * @param maintenanceKey the key required to be able to upgrade this contract
     * @param minterKey      the key required to be able to mint eigenauts 
     */ 
    function genesis(address locksmith, uint256 maintenanceKey, uint256 minterKey) external;

    /**
     * getLocksmith 
     *
     * @return the assigned governance locksmith that was set at genesis.
     */ 
    function getLocksmith() external view returns (address);

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
    function createEigenaut(string calldata eigenautURI, address recipient) external;

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
    function setEigenautDelegate(uint256 eigenautId, address delegate) external;

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
    function getEigenautDelegate(uint256 eigenautId) external view returns (address);
}
