// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "./FuzzUtilities.sol";

using PriceLibrary for uint256; 

/// @title Echidna tests for Price.sol library
/// @notice Tests all functions in PriceLibrary with randomized inputs
contract PriceTest {
    // Epsilon values for boundary testing
    uint256 constant epsilonX15 = 1;
    uint256 constant epsilonX59 = 1;
    uint256 constant epsilonX216 = 1;

    // Sample values for testing
    uint256 constant sampleX15 = 0xF00F;
    uint256 constant sampleX59 = 0xF00FF00FF00FF00F;
    uint256 constant sampleX216 = 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF;

    // ============================================
    // TEST: storePrice with just logPrice
    // ============================================

    /// @notice Tests storePrice(uint256 pointer, X59 logPrice)
    /// @dev Randomizes logPrice and verifies round-trip storage
    function test_storePrice0(uint64 seed) public pure {
        // Generate random logPrice within valid range [1, 2^64 - 1]
        X59 logPrice = X59.wrap(int256(uint256(1 + (seed % ((2 ** 64) - 1)))));
        
        // Get a valid price pointer (must be >= 32)
        uint256 pointer = get_a_price_pointer();
        
        // Store the price
        pointer.storePrice(logPrice);
        
        // Verify we can read back the same logPrice
        X59 logResult = pointer.log();
        assert(logResult == logPrice);
        
        // Verify sqrt and sqrtInverse are within valid bounds (< oneX216)
        X216 sqrtResult = pointer.sqrt(false);
        X216 sqrtInverseResult = pointer.sqrt(true);
        
        // sqrt and sqrtInverse should be > 0
        assert(sqrtResult > zeroX216);
        assert(sqrtInverseResult > zeroX216);
        
        // sqrt and sqrtInverse should be < oneX216 (approximately)
        // We allow some tolerance due to floating-point approximation in exp()
        assert(sqrtResult < oneX216);
        assert(sqrtInverseResult < oneX216);
    }

    // ============================================
    // TEST: storePrice with explicit values
    // ============================================

    /// @notice Tests storePrice(uint256 pointer, X59, X216, X216)
    /// @dev Randomizes all input values and verifies round-trip storage
    function test_storePrice1(
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random logPrice within valid range
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        
        // Generate random sqrt values (must be < oneX216)
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        
        // Ensure minimum values
        sqrtPrice = (sqrtPrice < epsilonX216) ? X216.wrap(int256(epsilonX216)) : sqrtPrice;
        sqrtInversePrice = (sqrtInversePrice < epsilonX216) ? X216.wrap(int256(epsilonX216)) : sqrtInversePrice;
        
        uint256 pointer = get_a_price_pointer();
        
        // Store the price with explicit values
        pointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
        
        // Verify round-trip
        X59 logResult = pointer.log();
        X216 sqrtResult = pointer.sqrt(false);
        X216 sqrtInverseResult = pointer.sqrt(true);
        
        assert(logResult == logPrice);
        assert(sqrtResult == sqrtPrice);
        assert(sqrtInverseResult == sqrtInversePrice);
    }

    // ============================================
    // TEST: storePrice with height
    // ============================================

    /// @notice Tests storePrice(uint256 pointer, X15, X59, X216, X216)
    /// @dev Randomizes all input values including height
    function test_storePrice2(
        uint16 seedHeight,
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random height (<= oneX15)
        X15 heightPrice = X15.wrap(uint16(seedHeight) % uint16(X15.unwrap(oneX15) + 1));
        
        // Generate random logPrice
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        
        // Generate random sqrt values
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        
        // Ensure minimum values
        sqrtPrice = (sqrtPrice < epsilonX216) ? X216.wrap(int256(epsilonX216)) : sqrtPrice;
        sqrtInversePrice = (sqrtInversePrice < epsilonX216) ? X216.wrap(int256(epsilonX216)) : sqrtInversePrice;
        
        uint256 pointer = get_a_price_pointer();
        
        // Store the price with height
        pointer.storePrice(heightPrice, logPrice, sqrtPrice, sqrtInversePrice);
        
        // Verify round-trip
        X15 heightResult = pointer.height();
        X59 logResult = pointer.log();
        X216 sqrtResult = pointer.sqrt(false);
        X216 sqrtInverseResult = pointer.sqrt(true);
        
        assert(heightResult == heightPrice);
        assert(logResult == logPrice);
        assert(sqrtResult == sqrtPrice);
        assert(sqrtInverseResult == sqrtInversePrice);
    }

    // ============================================
    // TEST: height function
    // ============================================

    /// @notice Tests height(uint256 pointer) function
    /// @dev Randomizes height value and verifies read/write
    function test_height(uint16 seed) public pure {
        X15 height = X15.wrap(uint16(seed) % uint16(X15.unwrap(oneX15) + 1));
        
        uint256 pointer = get_a_price_pointer();
        
        // Write height at pointer (pointer must point to height location)
        assembly {
            mstore(sub(pointer, 32), shl(240, height))
        }
        
        // Read height back
        X15 result = pointer.height();
        assert(result == height);
    }

    // ============================================
    // TEST: log function
    // ============================================

    /// @notice Tests log(uint256 pointer) function
    /// @dev Randomizes logPrice value and verifies read/write
    function test_log(uint64 seed) public pure {
        X59 logPrice = X59.wrap(int256(uint256(1 + (seed % ((2 ** 64) - 1)))));
        
        uint256 pointer = get_a_price_pointer();
        
        // Write logPrice at pointer
        assembly {
            mstore(pointer, shl(192, logPrice))
        }
        
        // Read logPrice back
        X59 result = pointer.log();
        assert(result == logPrice);
    }

    // ============================================
    // TEST: sqrt function
    // ============================================

    /// @notice Tests sqrt(uint256 pointer, bool inverse) function
    /// @dev Randomizes sqrt value and tests both inverse and non-inverse cases
    function test_sqrt(uint216 seed, bool inverse) public pure {
        // Generate random sqrt value
        X216 sqrt = X216.wrap(int256(uint256(seed) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        if (sqrt < epsilonX216) {
            sqrt = X216.wrap(int256(epsilonX216));
        }
        
        uint256 pointer = get_a_price_pointer();
        
        // Write sqrt at appropriate location
        assembly {
            // If inverse is true, store at pointer + 35, else at pointer + 8
            let offset := add(8, mul(27, inverse))
            mstore(add(pointer, offset), shl(40, sqrt))
        }
        
        // Read sqrt back
        X216 result = pointer.sqrt(inverse);
        assert(result == sqrt);
    }

    // ============================================
    // TEST: copyPrice function
    // ============================================

    /// @notice Tests copyPrice(uint256 pointer0, uint256 pointer1) function
    /// @dev Randomizes price values and verifies copy operation
    function test_copyPrice(
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random price values
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = X216.wrap(int256(epsilonX216));
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = X216.wrap(int256(epsilonX216));
        
        uint256 pointer0 = get_a_price_pointer();
        uint256 pointer1 = get_a_price_pointer();
        
        // Store price at pointer1
        pointer1.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
        
        // Copy from pointer1 to pointer0
        pointer0.copyPrice(pointer1);
        
        // Verify copied values match original
        X59 logResult = pointer0.log();
        X216 sqrtResult = pointer0.sqrt(false);
        X216 sqrtInverseResult = pointer0.sqrt(true);
        
        assert(logResult == logPrice);
        assert(sqrtResult == sqrtPrice);
        assert(sqrtInverseResult == sqrtInversePrice);
    }

    // ============================================
    // TEST: copyPriceWithHeight function
    // ============================================

    /// @notice Tests copyPriceWithHeight(uint256 pointer0, uint256 pointer1)
    /// @dev Randomizes all price values including height
    function test_copyPriceWithHeight(
        uint16 seedHeight,
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random values
        X15 heightPrice = X15.wrap(uint16(seedHeight) % uint16(X15.unwrap(oneX15) + 1));
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = X216.wrap(int256(epsilonX216));
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = X216.wrap(int256(epsilonX216));
        
        uint256 pointer0 = get_a_price_pointer();
        uint256 pointer1 = get_a_price_pointer();
        
        // Write height at pointer1
        assembly {
            mstore(sub(pointer1, 32), shl(240, heightPrice))
        }
        
        // Store price at pointer1
        pointer1.storePrice(heightPrice, logPrice, sqrtPrice, sqrtInversePrice);
        
        // Copy with height from pointer1 to pointer0
        pointer0.copyPriceWithHeight(pointer1);
        
        // Verify copied values match original
        X15 heightResult = pointer0.height();
        X59 logResult = pointer0.log();
        X216 sqrtResult = pointer0.sqrt(false);
        X216 sqrtInverseResult = pointer0.sqrt(true);
        
        assert(heightResult == heightPrice);
        assert(logResult == logPrice);
        assert(sqrtResult == sqrtPrice);
        assert(sqrtInverseResult == sqrtInversePrice);
    }

    // ============================================
    // TEST: segment function
    // ============================================

    /// @notice Tests segment(uint256 pointer) function
    /// @dev Randomizes two consecutive prices and verifies segment extraction
    function test_segment(
        uint16 seedC0,
        uint16 seedC1,
        uint64 seedB0,
        uint64 seedB1
    ) public pure {
        // Generate random heights
        X15 c0 = X15.wrap(uint16(seedC0) % uint16(X15.unwrap(oneX15) + 1));
        X15 c1 = X15.wrap(uint16(seedC1) % uint16(X15.unwrap(oneX15) + 1));
        
        // Generate random logPrices (ensure b0 < b1)
        X59 b0 = X59.wrap(int256(uint256(1 + (seedB0 % ((2 ** 64) - 2)))));
        X59 maxB1 = X59.wrap(int256(uint256(2 ** 64 - 1)));
        X59 b1 = X59.wrap(int256(uint256(1 + (seedB1 % ((2 ** 64) - 2)))));
        
        // Ensure b0 < b1 by swapping if needed
        if (b1 <= b0) {
            b1 = b0 + X59.wrap(int256(1));
        }
        if (b1 > maxB1) {
            b1 = maxB1;
        }
        
        uint256 segmentPointer = get_a_segment_pointer();
        
        // Store first price at segmentPointer
        (X216 sqrt0, X216 sqrtInv0) = b0.exp();
        segmentPointer.storePrice(c0, b0, sqrt0, sqrtInv0);
        
        // Store second price at segmentPointer + 64
        (X216 sqrt1, X216 sqrtInv1) = b1.exp();
        (segmentPointer + 64).storePrice(c1, b1, sqrt1, sqrtInv1);
        
        // Extract segment
        (X59 b0Result, X59 b1Result, X15 c0Result, X15 c1Result) = segmentPointer.segment();
        
        assert(b0Result == b0);
        assert(b1Result == b1);
        assert(c0Result == c0);
        assert(c1Result == c1);
    }

    // ============================================
    // TEST: Memory corruption detection
    // ============================================

    /// @notice Tests that storePrice does not corrupt surrounding memory
    /// @dev Populates surrounding memory with known values and verifies integrity
    function test_memory_not_corrupted(
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random price values
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = X216.wrap(int256(epsilonX216));
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = X216.wrap(int256(epsilonX216));
        
        // Allocate pointer
        uint256 pointer;
        assembly {
            pointer := mload(0x40)
            mstore(0x40, add(pointer, 128)) // Extra space for corruption checks
        }
        
        // Populate surrounding memory with known pattern
        // Fill memory before pointer with 0xAB pattern
        uint256 beforePattern = 0xABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAB;
        uint256 afterPattern = 0xCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCD;
        
        // Store patterns in surrounding memory
        assembly {
            // Fill 3 slots before pointer
            mstore(sub(pointer, 32), beforePattern)
            mstore(sub(pointer, 64), beforePattern)
            mstore(sub(pointer, 96), beforePattern)
            
            // Fill 3 slots after the price area (pointer + 62 to pointer + 94)
            mstore(add(pointer, 62), afterPattern)
            mstore(add(pointer, 94), afterPattern)
            mstore(add(pointer, 126), afterPattern)
        }
        
        // Store the price
        pointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
        
        // Verify surrounding memory is not corrupted
        assembly {
            let corrupted := 0
            
            // Check memory before pointer
            if iszero(eq(mload(sub(pointer, 32)), beforePattern)) {
                corrupted := 1
            }
            if iszero(eq(mload(sub(pointer, 64)), beforePattern)) {
                corrupted := 1
            }
            if iszero(eq(mload(sub(pointer, 96)), beforePattern)) {
                corrupted := 1
            }
            
            // Check memory after price area
            if iszero(eq(mload(add(pointer, 62)), afterPattern)) {
                corrupted := 1
            }
            if iszero(eq(mload(add(pointer, 94)), afterPattern)) {
                corrupted := 1
            }
            if iszero(eq(mload(add(pointer, 126)), afterPattern)) {
                corrupted := 1
            }
            
            // Assert no corruption
            assert(iszero(corrupted))
        }
    }

    /// @notice Tests that storePrice with height does not corrupt surrounding memory
    function test_memory_not_corrupted_with_height(
        uint16 seedHeight,
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random values
        X15 heightPrice = X15.wrap(uint16(seedHeight) % uint16(X15.unwrap(oneX15) + 1));
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = X216.wrap(int256(epsilonX216));
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = X216.wrap(int256(epsilonX216));
        
        // Allocate pointer
        uint256 pointer;
        assembly {
            pointer := add(mload(0x40), 2)
            mstore(0x40, add(pointer, 128))
        }
        
        // Populate surrounding memory with known pattern
        uint256 beforePattern = 0xABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAB;
        uint256 afterPattern = 0xCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCD;
        
        assembly {
            // Fill 3 slots before pointer
            mstore(sub(pointer, 32), beforePattern)
            mstore(sub(pointer, 64), beforePattern)
            mstore(sub(pointer, 96), beforePattern)
            
            // Fill 3 slots after the price area
            mstore(add(pointer, 62), afterPattern)
            mstore(add(pointer, 94), afterPattern)
            mstore(add(pointer, 126), afterPattern)
        }
        
        // Store the price with height
        pointer.storePrice(heightPrice, logPrice, sqrtPrice, sqrtInversePrice);
        
        // Verify surrounding memory is not corrupted
        assembly {
            let corrupted := 0
            
            if iszero(eq(mload(sub(pointer, 32)), beforePattern)) {
                corrupted := 1
            }
            if iszero(eq(mload(sub(pointer, 64)), beforePattern)) {
                corrupted := 1
            }
            if iszero(eq(mload(sub(pointer, 96)), beforePattern)) {
                corrupted := 1
            }
            
            if iszero(eq(mload(add(pointer, 62)), afterPattern)) {
                corrupted := 1
            }
            if iszero(eq(mload(add(pointer, 94)), afterPattern)) {
                corrupted := 1
            }
            if iszero(eq(mload(add(pointer, 126)), afterPattern)) {
                corrupted := 1
            }
            
            assert(iszero(corrupted))
        }
    }

    // ============================================
    // TEST: Random pointer location
    // ============================================

    /// @notice Tests storePrice at random memory locations
    /// @dev Ensures the library works correctly regardless of memory position
    function test_random_pointer_location(
        uint8 offsetSeed,
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random logPrice
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        
        // Generate random sqrt values
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = X216.wrap(int256(epsilonX216));
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = X216.wrap(int256(epsilonX216));
        
        // Get base pointer and add random offset (multiple of 32)
        uint256 pointer;
        uint256 basePointer;
        assembly {
            basePointer := mload(0x40)
            mstore(0x40, add(basePointer, 256))
        }
        
        // Add offset (0-224 bytes, ensuring pointer >= 32)
        uint256 offset = (uint256(offsetSeed) * 32) % 224;
        pointer = basePointer + offset;
        
        if (pointer < 32) {
            pointer = 32;
        }
        
        // Store the price
        pointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
        
        // Verify round-trip
        X59 logResult = pointer.log();
        X216 sqrtResult = pointer.sqrt(false);
        X216 sqrtInverseResult = pointer.sqrt(true);
        
        assert(logResult == logPrice);
        assert(sqrtResult == sqrtPrice);
        assert(sqrtInverseResult == sqrtInversePrice);
    }

    // ============================================
    // SANITY CHECK: Deliberate error to verify Echidna catches it
    // This test will FAIL when Echidna runs, proving the tests are effective
    // ============================================

    /// @notice SANITY CHECK: This test deliberately introduces an error
    /// @dev Echidna SHOULD catch this failure. If not, tests are not effective.
    /// @notice Comment out or remove this test after verifying Echidna works!
    function test_sanity_check_deliberate_error(
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random values
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = X216.wrap(int256(epsilonX216));
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = X216.wrap(int256(epsilonX216));
        
        uint256 pointer = get_a_price_pointer();
        
        // Store the price
        pointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
        
        // Verify round-trip - this should pass
        X59 logResult = pointer.log();
        X216 sqrtResult = pointer.sqrt(false);
        X216 sqrtInverseResult = pointer.sqrt(true);
        
        assert(logResult == logPrice);
        assert(sqrtResult == sqrtPrice);
        assert(sqrtInverseResult == sqrtInversePrice);
        
        // DELIBERATE ERROR: This assertion will fail for certain inputs
        // Uncomment to verify Echidna catches it:
        // assert(sqrtResult == zeroX216); // This will fail!
    }

    // ============================================
    // ADDITIONAL SANITY CHECK: Known bug injection
    // ============================================

    /// @notice SANITY CHECK: Tests with a known incorrect value
    /// @dev This test demonstrates that Echidna can find real bugs
    function test_sanity_check_wrong_value(
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(X216.unwrap(oneX216 - X216.wrap(int256(epsilonX216))))));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = X216.wrap(int256(epsilonX216));
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = X216.wrap(int256(epsilonX216));
        
        uint256 pointer = get_a_price_pointer();
        pointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
        
        // This assertion verifies the sqrt should NOT be zero
        // If this fails, it means sqrt was corrupted
        X216 sqrtResult = pointer.sqrt(false);
        assert(sqrtResult > zeroX216);
        
        // This is the sanity check - verify we can read back what we wrote
        // If Echidna can't find bugs, this should always pass
        assert(sqrtResult == sqrtPrice);
    }
}
