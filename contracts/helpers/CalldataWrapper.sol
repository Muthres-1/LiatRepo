// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import "../utilities/Calldata.sol";
import {
  getFreeMemoryPointer,
  getHookInputByteCount,
  _hookInputByteCount_ 
} from "../utilities/Memory.sol";
import {writeStorage} from "../utilities/Storage.sol";


/// @title This contract exposes the internal functions of 'Calldata.sol' for 
/// testing purposes.
contract CalldataWrapper {
  function _readInitializeInput() public returns (
    KernelCompact kernelCompact
  ) {
    kernelCompact = readInitializeInput();
    uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      log1(0, freeMemoryPointer, 0)
    }
  }
// log1(memory_start, memory_size, topic1) :- log1 is an EVM assembly opcode used to emit an event with 1 topic.
// 0x00 ------------------- used memory ------------------- freeMemoryPointer ---- free memory ,freeMemoryPointer = memory size for here because memory starts at 0x00, so the size of used memory is equal to the pointer to the start of free memory. So we log from 0x00 to freeMemoryPointer.
// emit meaning → write an event log into the transaction receipt or Store this information in transaction receipt(not storage of the contract).
// topic means  → searchable label of the log
// topic1       → value of that label
// log1         → emit event with 1 topic or It stores memory[memory_start : memory_start + memory_size] into the blockchain logs with 1 topic. It Store this information in transaction receipt(not storage of the contract) so that it can be accessed by off-chain applications or other contracts. The log will contain the data from memory[0 : freeMemoryPointer] and will be indexed by topic1 (which is 0 in this case).
  function _readModifyPositionInput() public {
    readModifyPositionInput();
    uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      log1(0, freeMemoryPointer, 0)
    }
  }

  function _readDonateInput() public {
    readDonateInput();
    uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      log1(0, freeMemoryPointer, 0)
    }
  }

  function _readModifyKernelInput() public returns (
    KernelCompact kernelCompact
  ) {
    kernelCompact = readModifyKernelInput();
    uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      log1(0, freeMemoryPointer, 0)
    }
  }

  function _readModifyPoolGrowthPortionInput() public {
    readModifyPoolGrowthPortionInput();
    uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      log1(0, freeMemoryPointer, 0)
    }
  }

  function _readUpdateGrowthPortionsInput() public {
    readUpdateGrowthPortionsInput();
    uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      log1(0, freeMemoryPointer, 0)
    }
  }

  function _readSwapInput() public {
    readSwapInput();
    uint256 hookInputByteCount = getHookInputByteCount();
    assembly {
      log1(
        0,
        add(add(_hookInputByteCount_, hookInputByteCount), 32),
        0
      )
    }
  }
 
  function _readCollectInput() public {
    readCollectInput();
    uint256 freeMemoryPointer = getFreeMemoryPointer();
    assembly {
      log1(0, freeMemoryPointer, 0)
    }
  }
}


