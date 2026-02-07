// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CalldataWrapper} from "../contracts/helpers/CalldataWrapper.sol";
import { _endOfStaticParams_, getFreeMemoryPointer } from "../contracts/utilities/Memory.sol";

contract CalldataTestWithBug {
    CalldataWrapper public wrapper;
    uint256 constant HOOK_DATA_PLACEMENT = _endOfStaticParams_ + 32;
    uint256 constant MAX_HOOK_SIZE = 256;
    
    constructor() { wrapper = new CalldataWrapper(); }
    
    function testBugWrongFMP(uint256 seed, uint16 hookOffset, uint16 rawHookSize) public {
        hookOffset = hookOffset % 256;
        uint16 hookSize = uint16((rawHookSize % MAX_HOOK_SIZE) + 1);
        
        uint256 totalSize = 260 + hookOffset + hookSize;
        bytes memory cd = new bytes(totalSize);
        
        for (uint256 i = 0; i < totalSize; i++) {
            cd[i] = bytes1(uint8(seed >> (8 * (i % 32))));
        }
        
        cd[0] = 0xc2; cd[1] = 0x4b; cd[2] = 0x9e; cd[3] = 0xa0;
        
        uint256 pid = uint256(keccak256(abi.encode(seed)));
        pid = (pid & ~(uint256(0xFF) << 180)) | (uint256(100) << 180);
        for (uint256 i = 0; i < 32; i++) { cd[4 + i] = bytes1(uint8(pid >> (8 * (31 - i)))); }
        
        cd[36] = 0xFF; cd[67] = 0x01;
        cd[68] = 0xFF; cd[99] = 0x02;
        cd[100] = 0x01;
        
        uint256 hookPtr = 164 + hookOffset;
        for (uint256 i = 0; i < 32; i++) { cd[132 + i] = bytes1(uint8(hookPtr >> (8 * (31 - i)))); }
        
        for (uint256 i = 0; i < 32; i++) { cd[hookPtr + i] = bytes1(uint8(hookSize >> (8 * (31 - i)))); }
        
        for (uint256 i = 0; i < hookSize; i++) { cd[hookPtr + 32 + i] = bytes1(uint8(seed >> (8 * ((i + 7) % 32)))); }
        
        (bool ok, ) = address(wrapper).call(cd);
        
        if (ok) {
            uint256 fmp = getFreeMemoryPointer();
            assert(fmp == HOOK_DATA_PLACEMENT - hookSize);
        }
    }
    
    function testBugWrongHookPlacement(uint256 seed, uint16 rawSize) public {
        uint16 size = uint16((rawSize % MAX_HOOK_SIZE) + 1);
        
        bytes memory cd = new bytes(260 + size);
        
        for (uint256 i = 0; i < cd.length; i++) {
            cd[i] = bytes1(uint8(seed >> (8 * (i % 32))));
        }
        
        cd[0] = 0xc2; cd[1] = 0x4b; cd[2] = 0x9e; cd[3] = 0xa0;
        
        uint256 pid = uint256(keccak256(abi.encode(seed)));
        pid = (pid & ~(uint256(0xFF) << 180)) | (uint256(100) << 180);
        for (uint256 i = 0; i < 32; i++) { cd[4 + i] = bytes1(uint8(pid >> (8 * (31 - i)))); }
        
        cd[36] = 0xFF; cd[67] = 0x01;
        cd[68] = 0xFF; cd[99] = 0x02;
        cd[100] = 0x01;
        
        for (uint256 i = 0; i < 32; i++) { cd[132 + i] = bytes1(uint8(196 >> (8 * (31 - i)))); }
        for (uint256 i = 0; i < 32; i++) { cd[196 + i] = bytes1(uint8(size >> (8 * (31 - i)))); }
        for (uint256 i = 0; i < size; i++) { cd[228 + i] = bytes1(uint8(seed >> (8 * ((i + 11) % 32)))); }
        
        (bool ok, ) = address(wrapper).call(cd);
        
        if (ok) {
            uint256 hdp;
            assembly { hdp := mload(0x88) }
            assert(hdp == _endOfStaticParams_ + 64);
        }
    }
    
    function testBugWrongCurvePlacement(uint256 seed) public {
        bytes memory cd = new bytes(260);
        
        for (uint256 i = 0; i < 260; i++) {
            cd[i] = bytes1(uint8(seed >> (8 * (i % 32))));
        }
        
        cd[0] = 0xc2; cd[1] = 0x4b; cd[2] = 0x9e; cd[3] = 0xa0;
        
        uint256 pid = uint256(keccak256(abi.encode(seed)));
        pid = (pid & ~(uint256(0xFF) << 180)) | (uint256(100) << 180);
        for (uint256 i = 0; i < 32; i++) { cd[4 + i] = bytes1(uint8(pid >> (8 * (31 - i)))); }
        
        cd[36] = 0xFF; cd[67] = 0x01;
        cd[68] = 0xFF; cd[99] = 0x02;
        cd[100] = 0x01;
        
        uint16 hookLen = 32;
        for (uint256 i = 0; i < 32; i++) { cd[132 + i] = bytes1(uint8(196 >> (8 * (31 - i)))); }
        for (uint256 i = 0; i < 32; i++) { cd[196 + i] = bytes1(uint8(hookLen >> (8 * (31 - i)))); }
        for (uint256 i = 0; i < hookLen; i++) { cd[228 + i] = bytes1(uint8(seed >> (8 * ((i + 7) % 32)))); }
        
        (bool ok, ) = address(wrapper).call(cd);
        
        if (ok) {
            uint256 cp;
            assembly { cp := mload(_endOfStaticParams_) }
            assert(cp == _endOfStaticParams_ + 32);
        }
    }
}
