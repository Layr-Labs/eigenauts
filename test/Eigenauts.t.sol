// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.23;

// Foundry Testing Framework
import {Test, console2} from "forge-std/Test.sol";

// Governance Keys
import "lib/locksmith-core/src/interfaces/ILocksmith.sol";
import { Locksmith } from "lib/locksmith-core/src/Locksmith.sol";
import { KeyLocker } from "lib/locksmith-core/src/KeyLocker.sol";
import {
    InvalidRingKey
} from "lib/locksmith-core/src/interfaces/ILocksmith.sol";

// Token Contract
import { IEigenauts } from "../src/interfaces/IEigenauts.sol";
import { Eigenauts } from "../src/Eigenauts.sol";

// Upgradeable Proxy Contract
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// Enables the test contract to receive keys and eigenauts
import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

// Error stubs for testing

contract EigenautsTest is Test, ERC721Holder, ERC1155Holder {
    Locksmith public locksmith; 
    ERC1967Proxy public proxy;
    Eigenauts public nauts;
    Eigenauts public implementation;

    uint256 public RING_ID;
    uint256 public ROOT_KEY;
    uint256 public MAINTENANCE_KEY;
    uint256 public MINTER_KEY;

    bool public reenter;

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

        // proxy
        proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(Eigenauts.genesis.selector, locksmith, MAINTENANCE_KEY, MINTER_KEY));

        // store a copy as an eigenaut contract 
        nauts = Eigenauts(address(proxy));
    }

    // try to run genesis after a naked deployment and it just fails. this will
    // essentially brick the contract but that is what it is 
    function test_MustBeDeployerForGenesis() public {
        Eigenauts badnauts = new Eigenauts();
        vm.expectRevert(Initializable.InvalidInitialization.selector); 
        badnauts.genesis(address(locksmith), 0, 0); 
    }

    // the keys provided need to have the same associated
    // key ring.
    function test_ProvidedPermissionsMustHaveSameTrustRoot() public {
        // try to do it with an invalid key and it will fail
        vm.expectRevert(InvalidRingKey.selector);
        nauts = Eigenauts(address(new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(Eigenauts.genesis.selector, locksmith, MAINTENANCE_KEY, 99))
        ));

        // try to do it with two different trust roots and it will fail        
        (uint256 ring, uint256 root) = locksmith.createKeyRing(
            stb('Bad Ring'), stb('Mert'), 'https://0xmert.com/liveness', address(this));
        assertEq(1, ring);
        vm.expectRevert('ROOT_TRUST_MISMATCH');
        nauts = Eigenauts(address(new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(Eigenauts.genesis.selector, locksmith, MAINTENANCE_KEY, root))
        ));
    }

    // given the setup, ensure the event is emitted,
    // and all reasonably introspectable state is its proper intial values,
    // and that genesis can not be called twice
    function test_SaneGenesis() public view {
        // check the locksmith reference
        assertEq(address(locksmith), nauts.getLocksmith());

        // check the key definitions
        assertEq(nauts.MAINTAINER_KEY(), MAINTENANCE_KEY);
        assertEq(MINTER_KEY, nauts.MINTER_KEY());

        // check the population
        assertEq(nauts.population(), 0);

        // token uris should be empty
        assertEq(nauts.tokenURI(0), '');

        // interface support should be for both Eigenauts and ERC721
        assertEq(true, nauts.supportsInterface(type(IEigenauts).interfaceId));
        assertEq(true, nauts.supportsInterface(type(IERC721).interfaceId));
    }

    // ensure that only the maintenance key can upgrade the contract
    function test_UpgradesAreGuarded() public {
        // we need a new implementation 
        Eigenauts upgradeImpl = new Eigenauts();

        // prank to something not holding the maintenance key,
        // and upgrading should fail
        vm.prank(address(0x1234));
        vm.expectRevert('REQUIRED_KEY_MISSING');
        nauts.upgradeToAndCall(address(upgradeImpl), '');

        // only that single call was pranked. It should
        // revert to this contract, which is holding the
        // maintainer key.
        nauts.upgradeToAndCall(address(upgradeImpl), '');

        // that should pass, now burn the maintainer key
        // it should still work because I'm holding the root key 
        Eigenauts newImpl = new Eigenauts();
        locksmith.burnKey(ROOT_KEY, MAINTENANCE_KEY, address(this), 1);
        assertEq(0, locksmith.balanceOf(address(this), MAINTENANCE_KEY));
        nauts.upgradeToAndCall(address(newImpl), '');
       
        // now re-mint the maintainer key, and get rid of my
        // root key and it should work 
        locksmith.copyKey(ROOT_KEY, MAINTENANCE_KEY, address(this), false); 
        locksmith.burnKey(ROOT_KEY, ROOT_KEY, address(this), 1);
        nauts.upgradeToAndCall(address(newImpl), '');

        // now get rid of the maintainer key, and it
        // should fail again
        KeyLocker locker = new KeyLocker();
        locksmith.safeTransferFrom(address(this), address(locker), MAINTENANCE_KEY, 1, '');
        vm.expectRevert('REQUIRED_KEY_MISSING');
        nauts.upgradeToAndCall(address(upgradeImpl), '');
    }

    // any old shmo can't mint an eigenaut 
    function test_MustHoldMinterKeyToCreateEigenaut() public {
        locksmith.burnKey(ROOT_KEY, MINTER_KEY, address(this), 1);
        locksmith.burnKey(ROOT_KEY, ROOT_KEY, address(this), 1);
        vm.expectRevert('REQUIRED_KEY_MISSING');
        nauts.createEigenaut('', address(this));
    }
    
    // the root key holder can mint an eigenaut 
    function test_RootKeyHolderCanCreateEigenaut() public {
        // destroy the minter key, but still hold root
        locksmith.burnKey(ROOT_KEY, MINTER_KEY, address(this), 1);
        assertEq(0, nauts.population()); 
        nauts.createEigenaut('https://eigenlayer.xyz/eigenauts/0', address(this));
        assertEq(address(this), nauts.ownerOf(0));
        assertEq(1, nauts.population()); 
        assertEq('https://eigenlayer.xyz/eigenauts/0', nauts.tokenURI(0));

        // destroy the root key, and the party stops 
        locksmith.burnKey(ROOT_KEY, ROOT_KEY, address(this), 1);
        vm.expectRevert('REQUIRED_KEY_MISSING');
        nauts.createEigenaut('', address(this));
    }
    
    // the minter key holder can mint an eigenaut 
    function test_MinterKeyHolderCanCreateEigenaut() public {
        // destroy the root key, but still hold root
        locksmith.burnKey(ROOT_KEY, ROOT_KEY, address(this), 1);
        assertEq(0, nauts.population()); 
        nauts.createEigenaut('https://eigenlayer.xyz/eigenauts/0', address(this));
        assertEq(address(this), nauts.ownerOf(0));
        assertEq(1, nauts.population()); 
        assertEq('https://eigenlayer.xyz/eigenauts/0', nauts.tokenURI(0));
        
        // get rid of the minter key, and the party stops 
        KeyLocker locker = new KeyLocker();
        locksmith.safeTransferFrom(address(this), address(locker), MINTER_KEY, 1, '');
        vm.expectRevert('REQUIRED_KEY_MISSING');
        nauts.createEigenaut('', address(this));
    }

    // mint multiple ones to ensure that the events and the population incrementing works
    // check URIs too
    function test_MintMultipleEigenauts() public {
        nauts.createEigenaut('https://eigenlayer.xyz/eigenauts/0', address(this));
        assertEq(address(this), nauts.ownerOf(0));
        assertEq(1, nauts.population());
        assertEq('https://eigenlayer.xyz/eigenauts/0', nauts.tokenURI(0));

        nauts.createEigenaut('https://eigenlayer.xyz/eigenauts/1', address(0x1234));
        assertEq(address(0x1234), nauts.ownerOf(1));
        assertEq(2, nauts.population());
        assertEq('https://eigenlayer.xyz/eigenauts/1', nauts.tokenURI(1));
        
        nauts.createEigenaut('https://eigenlayer.xyz/eigenauts/2', address(0x12345));
        assertEq(address(0x12345), nauts.ownerOf(2));
        assertEq(3, nauts.population());
        assertEq('https://eigenlayer.xyz/eigenauts/2', nauts.tokenURI(2));
    }

    function test_DelegatingNonExistantEigenautFails() public {
        vm.expectRevert();
        nauts.setEigenautDelegate(0, address(0x1234));
    }

    // make sure that a user must be holding the eigenaut they are attempting to delegate
    function test_MustHoldEigenautToDelegate() public {
        // mint an eigenaut to someone else
        nauts.createEigenaut('', address(0x1234));

        // this contract can't delegate it
        vm.expectRevert('EIGENAUT_MISSING');
        nauts.setEigenautDelegate(0, address(0x1234));
    }

    // successfully delegate, and re-delegate the eigenaut
    function test_DelegateAndRedelegateEigenaut() public {
        // inspect event on creation
        vm.expectEmit(address(nauts));
        emit IEigenauts.EigenautCreated(address(this), MINTER_KEY, 0, '', address(this));
        nauts.createEigenaut('', address(this));
        
        // inspect event on delegation
        vm.expectEmit(address(nauts));
        emit IEigenauts.EigenautDelegation(address(this), 0, address(0x1234)); 
        nauts.setEigenautDelegate(0, address(0x1234));
        assertEq(address(0x1234), nauts.getEigenautDelegate(0)); 

        // redelegate
        vm.expectEmit(address(nauts));
        emit IEigenauts.EigenautDelegation(address(this), 0, address(0x4321)); 
        nauts.setEigenautDelegate(0, address(0x4321));
        assertEq(address(0x4321), nauts.getEigenautDelegate(0)); 
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
