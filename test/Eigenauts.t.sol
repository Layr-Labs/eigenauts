// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {Eigenauts} from "../src/Eigenauts.sol";

contract EigenautsTest is Test {
    Eigenauts public nauts;

    function setUp() public {
        nauts = new Eigenauts();
    }

    function test_Sanity() public {
    }
}
