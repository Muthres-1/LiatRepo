// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "./FuzzUtilities.sol";
 
using PriceLibrary for uint256; 

/// @title Echidna tests for Price.sol library
/// @notice Tests all functions in PriceLibrary with randomized inputs
contract PriceTest { 
    

    function test_storePrice0(uint64 seed) public pure {
        X59 logPrice = X59.wrap(int256(uint256(1 + (seed % ((2 ** 64) - 1)))));
        uint256 pointer = get_a_price_pointer();
        pointer.storePrice(logPrice);

        // Verify we can read back the same logPrice
        X59 logResult = pointer.log();
        assert(logResult == logPrice);
        X216 sqrtResult = pointer.sqrt(false);
        X216 sqrtInverseResult = pointer.sqrt(true);

        // sqrt and sqrtInverse should be > 0, zeroX216 is zero in x216
        assert(sqrtResult > zeroX216);
        assert(sqrtInverseResult > zeroX216);
        
        // sqrt and sqrtInverse should be < oneX216 (approximately), oneX216 is 1 in x216
        assert(sqrtResult < oneX216);
        assert(sqrtInverseResult < oneX216);
    }


    function test_storePrice1(
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        
        // Generate random sqrt values (must be < oneX216)
        int256 maxValue = X216.unwrap(oneX216) - X216.unwrap(epsilonX216);
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(maxValue)));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(maxValue)));
        
        // Ensure minimum values
        sqrtPrice = (sqrtPrice < epsilonX216) ? epsilonX216 : sqrtPrice;
        sqrtInversePrice = (sqrtInversePrice < epsilonX216) ? epsilonX216 : sqrtInversePrice;
        
        uint256 pointer = get_a_price_pointer();
        
        // Store the price with explicit values
        pointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
        
        X59 logResult = pointer.log();
        X216 sqrtResult = pointer.sqrt(false);
        X216 sqrtInverseResult = pointer.sqrt(true);
        
        assert(logResult == logPrice);
        assert(sqrtResult == sqrtPrice);
        assert(sqrtInverseResult == sqrtInversePrice);
    }


    function test_storePrice2(
        uint16 seedHeight,
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random height (<= oneX15)
        X15 heightPrice = X15.wrap(uint16(seedHeight) % uint16(X15.unwrap(oneX15) + 1));
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        
        // Generate random sqrt values
        int256 maxValue = X216.unwrap(oneX216) - X216.unwrap(epsilonX216);
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(maxValue)));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(maxValue)));
        
        // Ensure minimum values
        sqrtPrice = (sqrtPrice < epsilonX216) ? epsilonX216 : sqrtPrice;
        sqrtInversePrice = (sqrtInversePrice < epsilonX216) ? epsilonX216 : sqrtInversePrice;
        
        uint256 pointer = get_a_price_pointer();
        
        // Store the price with height
        pointer.storePrice(heightPrice, logPrice, sqrtPrice, sqrtInversePrice);
        
        X15 heightResult = pointer.height();
        X59 logResult = pointer.log();
        X216 sqrtResult = pointer.sqrt(false);
        X216 sqrtInverseResult = pointer.sqrt(true);
        
        assert(heightResult == heightPrice);
        assert(logResult == logPrice);
        assert(sqrtResult == sqrtPrice);
        assert(sqrtInverseResult == sqrtInversePrice);
    }


    function test_height(uint16 seed) public pure {
        X15 height = X15.wrap(uint16(seed) % uint16(X15.unwrap(oneX15) + 1));
        
        uint256 pointer = get_a_price_pointer();
        
        // Here it should be mstore(sub(pointer, 2), shl(240, height)) to correct but we did as following so it will show failure
        assembly {
            mstore(sub(pointer, 32), shl(240, height))
        }
        
        // Read height back
        X15 result = pointer.height();
        assert(result == height);
    }


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



    function test_sqrt(uint216 seed, bool inverse) public pure {
        // Generate random sqrt value
        int256 maxValue = X216.unwrap(oneX216) - X216.unwrap(epsilonX216);
        X216 sqrt = X216.wrap(int256(uint256(seed) % uint256(maxValue)));
        if (sqrt < epsilonX216) {
            sqrt = epsilonX216;
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



    function test_copyPrice(
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random price values
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        int256 maxValue = X216.unwrap(oneX216) - X216.unwrap(epsilonX216);
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(maxValue)));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(maxValue)));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = epsilonX216;
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = epsilonX216;
        
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



    function test_copyPriceWithHeight(
        uint16 seedHeight,
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random values
        X15 heightPrice = X15.wrap(uint16(seedHeight) % uint16(X15.unwrap(oneX15) + 1));
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        int256 maxValue = X216.unwrap(oneX216) - X216.unwrap(epsilonX216);
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(maxValue)));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(maxValue)));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = epsilonX216;
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = epsilonX216;
        
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



    function test_memory_not_corrupted(
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random price values
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        int256 maxValue = X216.unwrap(oneX216) - X216.unwrap(epsilonX216);
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(maxValue)));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(maxValue)));

        if (sqrtPrice < epsilonX216) sqrtPrice = epsilonX216;
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = epsilonX216;
        
        // Allocate pointer
        uint256 pointer;
        assembly {
            pointer := mload(0x40)
            mstore(0x40, add(pointer, 128)) // Extra space for corruption checks
        }
        
        // Populate surrounding memory with known pattern
        // Use smaller hex values that fit in uint256
        uint256 beforePattern = 0xABABABABABABABABABABABABABABABAB;
        uint256 afterPattern = 0xCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCD;
        
        // Store patterns in surrounding memory
        assembly {
            // Fill 3 slots before pointer
            mstore(sub(pointer, 32), beforePattern) // Here we should not start from pointer -32 while it should start from pointer - 34 but we did as following so it will show failure
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
        bool corrupted = false;
        assembly {
            // Check memory before pointer
            if iszero(eq(mload(sub(pointer, 32)), beforePattern)) {
                corrupted := true
            }
            if iszero(eq(mload(sub(pointer, 64)), beforePattern)) {
                corrupted := true
            }
            if iszero(eq(mload(sub(pointer, 96)), beforePattern)) {
                corrupted := true
            }
            
            // Check memory after price area
            if iszero(eq(mload(add(pointer, 62)), afterPattern)) {
                corrupted := true
            }
            if iszero(eq(mload(add(pointer, 94)), afterPattern)) {
                corrupted := true
            }
            if iszero(eq(mload(add(pointer, 126)), afterPattern)) {
                corrupted := true
            }
        }
        
        assert(!corrupted);
    }

    function test_memory_not_corrupted_with_height(
        uint16 seedHeight,
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random values
        X15 heightPrice = X15.wrap(uint16(seedHeight) % uint16(X15.unwrap(oneX15) + 1));
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        int256 maxValue = X216.unwrap(oneX216) - X216.unwrap(epsilonX216);
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(maxValue)));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(maxValue)));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = epsilonX216;
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = epsilonX216;
        
        // Allocate pointer
        uint256 pointer;
        assembly {
            pointer := add(mload(0x40), 2) // 0x40 returns the next free memory slot 
            mstore(0x40, add(pointer, 128))
        }
        
        // Populate surrounding memory with known pattern
        uint256 beforePattern = 0xABABABABABABABABABABABABABABABAB;
        uint256 afterPattern = 0xCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCD;
        
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
        bool corrupted = false;
        assembly {
            if iszero(eq(mload(sub(pointer, 32)), beforePattern)) {
                corrupted := true
            }
            if iszero(eq(mload(sub(pointer, 64)), beforePattern)) {
                corrupted := true
            }
            if iszero(eq(mload(sub(pointer, 96)), beforePattern)) {
                corrupted := true
            }
            
            if iszero(eq(mload(add(pointer, 62)), afterPattern)) {
                corrupted := true
            }
            if iszero(eq(mload(add(pointer, 94)), afterPattern)) {
                corrupted := true
            }
            if iszero(eq(mload(add(pointer, 126)), afterPattern)) {
                corrupted := true
            }
        }
        
        assert(!corrupted);
    }


    function test_random_pointer_location(
        uint8 offsetSeed,
        uint64 seedLog,
        uint216 seedSqrt,
        uint216 seedSqrtInv
    ) public pure {
        // Generate random logPrice
        X59 logPrice = X59.wrap(int256(uint256(1 + (seedLog % ((2 ** 64) - 1)))));
        
        // Generate random sqrt values
        int256 maxValue = X216.unwrap(oneX216) - X216.unwrap(epsilonX216);
        X216 sqrtPrice = X216.wrap(int256(uint256(seedSqrt) % uint256(maxValue)));
        X216 sqrtInversePrice = X216.wrap(int256(uint256(seedSqrtInv) % uint256(maxValue)));
        
        if (sqrtPrice < epsilonX216) sqrtPrice = epsilonX216;
        if (sqrtInversePrice < epsilonX216) sqrtInversePrice = epsilonX216;
        
        // Create pointer with random offset
        uint256 basePointer;
        uint256 pointer;
        assembly {
            basePointer := mload(0x40)
            mstore(0x40, add(basePointer, 160))
            pointer := add(basePointer, mod(offsetSeed, 32))
        }
        
        // Store price at random offset
        pointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
        
        // Verify round-trip
        X59 logResult = pointer.log();
        X216 sqrtResult = pointer.sqrt(false);
        X216 sqrtInverseResult = pointer.sqrt(true);
        
        assert(logResult == logPrice);
        assert(sqrtResult == sqrtPrice);
        assert(sqrtInverseResult == sqrtInversePrice);
    }
}
