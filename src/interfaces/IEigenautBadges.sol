// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.23;

/////////////////////////////////////////////////////
// Eigenaut Badges
//
// The main features of the Eigenaut Badge contract is:
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

    /////////////////////////////////////////////////
    // Interface 
    /////////////////////////////////////////////////
    
    /**
     * initialize 
     *
     * This function is only designed to be called once,
     * and it can only be called by the deployer. In general,
     * this function should be called in the same transaction
     * as the deployment as best practice.
     *
     * The deployer provides an initial locksmith and a reference 
     * to the Eigenaut contract. Neither are designed to be changed.
     *
     * This method reverts if:
     * - The caller is not the deployer.
     * - Initialize function has already been executed once successfully.
     * - the keys provided are not validated on the same ring.
     *
     * @param locksmith      the locksmith used for governance keys
     * @param maintenanceKey the key required to be able to upgrade this contract
     */ 
    function initialize(address locksmith, uint256 maintenanceKey) external;

    /**
     * getLocksmith 
     *
     * @return the assigned governance locksmith that was set at genesis.
     */ 
    function getLocksmith() external view returns (address);

    /**
     * createBadge
     *
     * Any Eigenaut holder can create a badge. It takes metadata, which when
     * confined to the standard required for display is really all that
     * is needed. 
     *
     * The caller can optionally provide an array of eigenauts that should receive
     * this bad on creation.
     *
     * This method will revert if:
     * - The message sender is not holding the declared creator Eigenaut
     *
     * @param creator    The ID of the eigenaut that is taking ownership of creating this badge. 
     * @param badgeURI   This metadata URI must resolve to a properly formatted metadata JSON.
     * @param recipients Eigenaut NFT IDs you want to attach the badge to 
     */ 
    function createBadge(uint256 creator, string calldata badgeURI, uint256[] calldata recipients) external;
}
