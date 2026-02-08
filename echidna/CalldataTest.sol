// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
  
import {CalldataWrapper} from "../contracts/helpers/CalldataWrapper.sol";
import { _endOfStaticParams_, getFreeMemoryPointer } from "../contracts/utilities/Memory.sol";

contract CalldataTest {
    CalldataWrapper public wrapper;
    uint256 constant HOOK_DATA_PLACEMENT = _endOfStaticParams_ + 32;
    uint256 constant MAX_HOOK_SIZE = 256;
    
    constructor() { wrapper = new CalldataWrapper(); }
    
    function testFuzzed(uint256 seed, uint16 hookOffset, uint16 rawHookSize) public {
        hookOffset = hookOffset % 256;
        uint16 hookSize = uint16((rawHookSize % MAX_HOOK_SIZE) + 1);
        
        uint256 totalSize = 168 + hookOffset + hookSize;
        bytes memory cd = new bytes(totalSize);
        
        for (uint256 i = 0; i < totalSize; i++) {
            cd[i] = bytes1(uint8(seed >> (8 * (i % 32))));
        }
        
        cd[0] = 0xc2; cd[1] = 0x4b; cd[2] = 0x9e; cd[3] = 0xa0;
        
        uint256 pid = uint256(keccak256(abi.encode(seed)));
        pid = (pid & ~(uint256(0xFF) << 180)) | (uint256(100) << 180);
        for (uint256 i = 0; i < 32; i++) { cd[4 + i] = bytes1(uint8(pid >> (8 * (31 - i)))); }
        
        uint256 logPriceMin = (seed % (uint256(1) << 63)) + (uint256(1) << 63) + 1;
        for (uint256 i = 0; i < 32; i++) { cd[36 + i] = bytes1(uint8(logPriceMin >> (8 * (31 - i)))); }
        
        uint256 logPriceMax = logPriceMin + 1;
        for (uint256 i = 0; i < 32; i++) { cd[68 + i] = bytes1(uint8(logPriceMax >> (8 * (31 - i)))); }
        
        int256 shares = int256(uint256(seed) % (uint256(uint128(type(int128).max)))) + 1;
        for (uint256 i = 0; i < 32; i++) { cd[100 + i] = bytes1(uint8(uint256(shares) >> (8 * (31 - i)))); }
        
        uint256 hookPtr = 136 + hookOffset;
        for (uint256 i = 0; i < 32; i++) { cd[132 + i] = bytes1(uint8(hookPtr >> (8 * (31 - i)))); }
        
        for (uint256 i = 0; i < 32; i++) { cd[hookPtr + i] = bytes1(uint8(hookSize >> (8 * (31 - i)))); }
        
        for (uint256 i = 0; i < hookSize; i++) { cd[hookPtr + 32 + i] = bytes1(uint8(seed >> (8 * ((i + 7) % 32)))); }
        
        (bool ok, ) = address(wrapper).call(cd);
        
        if (ok) {
            uint256 fmp = getFreeMemoryPointer();
            assert(fmp == HOOK_DATA_PLACEMENT + hookSize);
        }
    }
    
    function testVaryingHookSize(uint256 seed, uint16 rawSize) public {
        uint16 size = uint16((rawSize % MAX_HOOK_SIZE) + 1);
        
        uint256 totalSize = 168 + size;
        bytes memory cd = new bytes(totalSize);
        
        for (uint256 i = 0; i < totalSize; i++) {
            cd[i] = bytes1(uint8(seed >> (8 * (i % 32))));
        }
        
        cd[0] = 0xc2; cd[1] = 0x4b; cd[2] = 0x9e; cd[3] = 0xa0;
        
        uint256 pid = uint256(keccak256(abi.encode(seed)));
        pid = (pid & ~(uint256(0xFF) << 180)) | (uint256(100) << 180);
        for (uint256 i = 0; i < 32; i++) { cd[4 + i] = bytes1(uint8(pid >> (8 * (31 - i)))); }
        
        uint256 logPriceMin = (seed % (uint256(1) << 63)) + (uint256(1) << 63) + 1;
        for (uint256 i = 0; i < 32; i++) { cd[36 + i] = bytes1(uint8(logPriceMin >> (8 * (31 - i)))); }
        
        uint256 logPriceMax = logPriceMin + 1;
        for (uint256 i = 0; i < 32; i++) { cd[68 + i] = bytes1(uint8(logPriceMax >> (8 * (31 - i)))); }
        
        int256 shares = int256(uint256(seed) % (uint256(uint128(type(int128).max)))) + 1;
        for (uint256 i = 0; i < 32; i++) { cd[100 + i] = bytes1(uint8(uint256(shares) >> (8 * (31 - i)))); }
        
        for (uint256 i = 0; i < 32; i++) { cd[132 + i] = bytes1(uint8(168 >> (8 * (31 - i)))); }
        for (uint256 i = 0; i < 32; i++) { cd[168 + i] = bytes1(uint8(size >> (8 * (31 - i)))); }
        for (uint256 i = 0; i < size; i++) { cd[200 + i] = bytes1(uint8(seed >> (8 * ((i + 11) % 32)))); }
        
        (bool ok, ) = address(wrapper).call(cd);
        
        if (ok) {
            uint256 fmp = getFreeMemoryPointer();
            assert(fmp == HOOK_DATA_PLACEMENT + size);
        }
    }
    
    function testArbitraryHookPosition(uint256 seed, uint16 position) public {
        position = position % 512;
        
        uint256 hookPtr = 136 + position;
        uint256 totalSize = hookPtr + 32 + 256;
        bytes memory cd = new bytes(totalSize);
        
        for (uint256 i = 0; i < totalSize; i++) {
            cd[i] = bytes1(uint8(seed >> (8 * (i % 32))));
        }
        
        cd[0] = 0xc2; cd[1] = 0x4b; cd[2] = 0x9e; cd[3] = 0xa0;
        
        uint256 pid = uint256(keccak256(abi.encode(seed)));
        pid = (pid & ~(uint256(0xFF) << 180)) | (uint256(100) << 180);
        for (uint256 i = 0; i < 32; i++) { cd[4 + i] = bytes1(uint8(pid >> (8 * (31 - i)))); }
        
        uint256 logPriceMin = (seed % (uint256(1) << 63)) + (uint256(1) << 63) + 1;
        for (uint256 i = 0; i < 32; i++) { cd[36 + i] = bytes1(uint8(logPriceMin >> (8 * (31 - i)))); }
        
        uint256 logPriceMax = logPriceMin + 1;
        for (uint256 i = 0; i < 32; i++) { cd[68 + i] = bytes1(uint8(logPriceMax >> (8 * (31 - i)))); }
        
        int256 shares = int256(uint256(seed) % (uint256(uint128(type(int128).max)))) + 1;
        for (uint256 i = 0; i < 32; i++) { cd[100 + i] = bytes1(uint8(uint256(shares) >> (8 * (31 - i)))); }
        
        for (uint256 i = 0; i < 32; i++) { cd[132 + i] = bytes1(uint8(hookPtr >> (8 * (31 - i)))); }
        
        uint16 hLen = 64;
        for (uint256 i = 0; i < 32; i++) { cd[hookPtr + i] = bytes1(uint8(hLen >> (8 * (31 - i)))); }
        for (uint256 i = 0; i < hLen; i++) { cd[hookPtr + 32 + i] = bytes1(uint8(seed >> (8 * ((i + 3) % 32)))); }
        
        (bool ok, ) = address(wrapper).call(cd);
        
        if (ok) {
            uint256 fmp = getFreeMemoryPointer();
            assert(fmp == HOOK_DATA_PLACEMENT + hLen);
        }
    }
}
