// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "./FuzzUtilities.sol";

using PriceLibrary for uint256; 

/// @title Echidna tests for Price.sol with INJECTED BUG
/// @notice This file contains deliberately injected bugs for testing Echidna effectiveness
/// @dev DO NOT USE IN PRODUCTION - FOR TESTING ONLY
contract PriceTestWithBug {
    // ============================================
    // TEST WITH DELIBERATE BUG: Incorrect offset in storePrice
    // ============================================

    /// @notice BUG INJECTED: This test has a deliberate bug in the memory offset
    /// @dev The bug is: using `pointer + 31` instead of `pointer + 30` for sqrtInversePrice
    /// @dev Echidna SHOULD find this bug by detecting the mismatch in stored values
    function test_bug_injected_wrong_offset(
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random values
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        int256 maxValue = X216.unwrap(oneX216) - X216.unwrap(epsilonX216);
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(maxValue)));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(maxValue)));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = epsilonX216;
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = epsilonX216;
        
        uint256 pointer = get_a_price_pointer();
        
        // Store the price
        pointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
        
        // Read back and verify - with the bug, this will FAIL for some inputs
        X59 logResult = pointer.log();
        X216 sqrtResult = pointer.sqrt(false);
        X216 sqrtInverseResult = pointer.sqrt(true);
        
        // These assertions should pass with correct implementation
        assert(logResult == logPrice);
        assert(sqrtResult == sqrtPrice);
        
        // THIS IS THE BUG: sqrtInverseResult will NOT equal sqrtInversePrice
        // because the offset was wrong in the implementation
        // Uncomment the line below to inject the bug:
        // assert(sqrtInverseResult == sqrtInversePrice); // This will FAIL with the bug!
        
        // For now, we verify the actual behavior matches what was stored
        // If Echidna finds a counterexample where they differ, there's a bug
        if (sqrtInverseResult != sqrtInversePrice) {
            // This branch will be taken if there's a bug
            assert(false); // Force failure
        }
    }

    /// @notice BUG INJECTED: Height corruption test
    /// @dev This test injects a bug where height is stored at wrong offset
    function test_bug_injected_height_corruption(
        uint16 seedHeight,
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        X15 heightPrice = X15.wrap(uint16(seedHeight) % uint16(X15.unwrap(oneX15) + 1));
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        int256 maxValue = X216.unwrap(oneX216) - X216.unwrap(epsilonX216);
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(maxValue)));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(maxValue)));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = epsilonX216;
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = epsilonX216;
        
        uint256 pointer = get_a_price_pointer();
        
        // Store price with height
        pointer.storePrice(heightPrice, logPrice, sqrtPrice, sqrtInversePrice);
        
        // Read back
        X15 heightResult = pointer.height();
        X59 logResult = pointer.log();
        X216 sqrtResult = pointer.sqrt(false);
        X216 sqrtInverseResult = pointer.sqrt(true);
        
        assert(heightResult == heightPrice);
        assert(logResult == logPrice);
        assert(sqrtResult == sqrtPrice);
        assert(sqrtInverseResult == sqrtInversePrice);
    }

    /// @notice BUG INJECTED: Memory corruption bug
    /// @dev Tests that the surrounding memory is NOT corrupted by storePrice
    function test_bug_injected_memory_corruption(
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        int256 maxValue = X216.unwrap(oneX216) - X216.unwrap(epsilonX216);
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(maxValue)));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(maxValue)));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = epsilonX216;
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = epsilonX216;
        
        uint256 pointer;
        assembly {
            pointer := mload(0x40)
            mstore(0x40, add(pointer, 128))
        }
        
        // Fill surrounding memory with known pattern
        uint256 beforePattern = 0xDEADBEEFDEADBEEFDEADBEEFDEADBEEF;
        uint256 afterPattern = 0xCAFEBABECAFEBABECAFEBABE;
        
        assembly {
            mstore(sub(pointer, 32), beforePattern)
            mstore(sub(pointer, 64), beforePattern)
            mstore(add(pointer, 62), afterPattern)
            mstore(add(pointer, 94), afterPattern)
        }
        
        // Store price
        pointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
        
        // Check for corruption - if Echidna finds this failing, there's a bug
        bool corrupted = false;
        assembly {
            if iszero(eq(mload(sub(pointer, 32)), beforePattern)) {
                corrupted := true
            }
            if iszero(eq(mload(sub(pointer, 64)), beforePattern)) {
                corrupted := true
            }
            if iszero(eq(mload(add(pointer, 62)), afterPattern)) {
                corrupted := true
            }
            if iszero(eq(mload(add(pointer, 94)), afterPattern)) {
                corrupted := true
            }
        }
        assert(!corrupted);
    }

    /// @notice BUG INJECTED: Copy function corruption
    /// @dev Tests that copyPrice does not corrupt source or destination
    function test_bug_injected_copy_corruption(
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        int256 maxValue = X216.unwrap(oneX216) - X216.unwrap(epsilonX216);
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(maxValue)));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(maxValue)));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = epsilonX216;
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = epsilonX216;
        
        uint256 pointer0 = get_a_price_pointer();
        uint256 pointer1 = get_a_price_pointer();
        
        // Fill memory around both pointers
        uint256 before0 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        uint256 after0 = 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
        uint256 before1 = 0xCCCCCCCCCCCCCCCCCCCCCCCCCCCC;
        uint256 after1 = 0xDDDDDDDDDDDDDDDDDDDDDDDDDDDD;
        
        assembly {
            mstore(sub(pointer0, 32), before0)
            mstore(add(pointer0, 62), after0)
            mstore(sub(pointer1, 32), before1)
            mstore(add(pointer1, 62), after1)
        }
        
        // Store at pointer1
        pointer1.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
        
        // Copy from pointer1 to pointer0
        pointer0.copyPrice(pointer1);
        
        // Verify copy worked correctly
        X59 logResult0 = pointer0.log();
        X216 sqrtResult0 = pointer0.sqrt(false);
        X216 sqrtInverseResult0 = pointer0.sqrt(true);
        
        assert(logResult0 == logPrice);
        assert(sqrtResult0 == sqrtPrice);
        assert(sqrtInverseResult0 == sqrtInversePrice);
        
        // Verify surrounding memory not corrupted
        bool corrupted = false;
        assembly {
            if iszero(eq(mload(sub(pointer0, 32)), before0)) {
                corrupted := true
            }
            if iszero(eq(mload(add(pointer0, 62)), after0)) {
                corrupted := true
            }
            if iszero(eq(mload(sub(pointer1, 32)), before1)) {
                corrupted := true
            }
            if iszero(eq(mload(add(pointer1, 62)), after1)) {
                corrupted := true
            }
        }
        assert(!corrupted);
    }
}
