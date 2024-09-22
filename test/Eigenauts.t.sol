// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.23;

// Foundry Testing Framework
import {Test, console2} from "forge-std/Test.sol";

// Governance Keys
import "lib/locksmith-core/src/interfaces/ILocksmith.sol";
import { Locksmith } from "lib/locksmith-core/src/Locksmith.sol";

// Token Contract
import { Eigenauts } from "../src/Eigenauts.sol";

// Upgradeable Proxy Contract
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// Enables the test contract to receive keys and eigenauts
import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";

contract EigenautsTest is Test, ERC721Holder, ERC1155Holder {
    Locksmith public locksmith; 
    Eigenauts public nauts;
    Eigenauts public implementation;

    uint256 public RING_ID;
    uint256 public ROOT_KEY;
    uint256 public MAINTENANCE_KEY;
    uint256 public MINTER_KEY;

    function setUp() public {
        // Deploy a Standard Locksmith
        locksmith = new Locksmith();
       
        // Create a Key Ring to use for governance
        (RING_ID, ROOT_KEY) = locksmith.createKeyRing(
            stb('Eigenaut Governance'), stb('Chief Hekarro'), 'https://Root-Key', address(this));  
        
        // Mint a maintainer key
        MAINTENANCE_KEY = locksmith.createKey(ROOT_KEY, stb('Eigenauts Maintainer'), 'https://Maintainer-Key', address(this), false);

        // Mint a minter key
        MINTER_KEY = locksmith.createKey(ROOT_KEY, stb('Eigenauts Minter'), 'https://Maintainer-Key', address(this), false);

        // Deploy the implementation Contract 
        implementation = new Eigenauts();

        // deploy an upgradeable proxy, and call genesis
        nauts = Eigenauts(address(new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(Eigenauts.genesis.selector, locksmith, MAINTENANCE_KEY, MINTER_KEY))
        ));
    }

    // try to run genesis by not being the deployer and it
    // should fail
    function test_MustBeDeployerForGenesis() public {

    }

    // the keys provided need to have the same associated
    // key ring.
    function test_ProvidedPermissionsMustHaveSameTrustRoot() public {
        // try to do it with an invalid key and it will fail

        // try to do it with two different trust roots and it will fail        
    }

    // deploy another upgradeable contract and ensure the event is emitted,
    // and all reasonably introspectable state is its proper intial values,
    // and that genesis can not be called twice
    function test_SaneGenesis() public {

        // check the locksmith reference

        // check the key definitions

        // check the population

        // token uris should be empty

        // interface support should be for both Eigenauts and ERC721
    }

    // ensure that only the maintenance key can upgrade the contract
    function test_UpgradesAreGuarded() public {

    }

    // ensure that only the minter can mint an eigenaut
    function test_MustHoldMinterKeyToCreateEigenaut() public {

    }

    // mint multiple ones to ensure that the events and the population incrementing works
    function test_MintMultipleEigenauts() public {

    }

    // try to re-enter the minting function on receipt and make sure
    // that there is no invariant issues
    function test_MaliciousReEntryOnMint() public {

    }

    // make sure that a user must be holding the eigenaut they are attempting to delegate
    function test_MustHoldEigenautToDelegate() public {

    }

    // successfully delegate, and re-delegate the eigenaut
    function test_DelegateAndRedelegateEigenaut() public {

    }

    /**
     * stringToBytes32
     *
     * Normally, the user is providing a string on the client side
     * and this is done with javascript. The easiest way to solve
     * this without creating more APIs on the contract and requiring
     * more gas is to give credit to this guy on stack overflow.
     *
     * https://ethereum.stackexchange.com/questions/9142/how-to-convert-a-string-to-bytes32
     *
     * @param source the string you want to convert
     * @return result the equivalent result of the same using ethers.js
     */
    function stb(string memory source) internal pure returns (bytes32 result) {
        // Note: I'm not using this portion because there isn't
        // a use case where this will be empty.
        // bytes memory tempEmptyStringTest = bytes(source);
        //if (tempEmptyStringTest.length == 0) {
        //    return 0x0;
        // }

        assembly {
            result := mload(add(source, 32))
        }
    }
}
