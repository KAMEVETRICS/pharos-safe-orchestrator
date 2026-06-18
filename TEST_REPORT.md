# Safe Orchestrator - Test Report

## Test Environment
- **Network**: Pharos Atlantic Testnet
- **RPC URL**: `https://atlantic.dplabs-internal.com`
- **Safe Factory**: `0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67`
- **Safe Singleton**: `0x29fcB43b46531BcA003ddC8FCB67FFE91900C762`
- **Mock USDC Address**: `0xb7a09F05d363E038e80ef8c49543255F6920a190`
- **Deployed Safe Proxy**: `0x7998D3C3aDC1e719eb82c34150c94d8265f25CE7`

## 1. Safe Deployment & Initialization
- **Action**: Deployed a Safe Proxy with 3 owners and a threshold of 2.
- **Owners**:
  - Owner 1: `0x47982F6C7b606868e50fAA35328d240959F9c166`
  - Owner 2: `0x7C9A2A4314482BCDD9aD7d5664A6CC8113b9a242`
  - Owner 3: `0x5b4130C0cB7Ce17406efBc3ae8450D5eD1c57D08`
- **Proxy Creation Hash**: `0xf11d1257a7611c20e7a4df1bbdf89ef30004c3e4023336d4285f1a06f3913b50`
- **Result**: ✅ Success. The Safe was initialized correctly with the specified owners and threshold.

## 2. Status Check
- **Action**: Queried the Safe's state variables.
- **Result**: ✅ Success.
  - Owners confirmed matching the deployment arguments.
  - Threshold confirmed as 2.
  - Nonce confirmed as 0.

## 3. Fund Safe
- **Action**: Sent 1 native PHRS token and 50 Mock USDC to the Safe to enable outgoing transactions.
- **Result**: ✅ Success.
  - Native PHRS Tx Hash: `0xa271b4cc17af432a4631f0fb1c72a194b8b984518068a03fc88e4599da9749b9`
  - Mock USDC Tx Hash: `0x4f06f18e281c91f34eebae23427825021c19a478bc8e189a7cfc11127c945c65`

## 4. Lifecycle Execution: Propose, Sign, and Execute
- **Action**: Orchestrated a multisig transaction to transfer 10 Mock USDC from the Safe to a target address (`0xaD55ddee566c2ACEa8d3f491248BdAC5e58Ed9c0`).
- **Propose**: Computed the Safe Transaction Hash for Nonce 0 (`0x84a5c5626d9c2e2563fcf8400d9c6a1608280ba897f43f51ae62b27f354f4a06`).
- **Sign**: Collected signatures from Owner 1 and Owner 2 using EIP-712 pure ECDSA (which Safe natively accepts without modifying `v`).
- **Execute**: Packed the signatures in ascending signer address order and called `execTransaction`.
- **Result**: ✅ Success. The transaction successfully executed and the 10 Mock USDC were transferred out of the Safe.
  - Execution Tx Hash: `0x65b84cea1dcaf6f1dd99742e6ca3501cff874ffba69662e1f4056d01b46261e6`

## 5. Threshold Failure Path Testing
- **Action**: Attempted to execute a second transfer using only 1 signature (threshold is 2).
- **Propose**: Computed Safe Transaction Hash for Nonce 1 (`0x03ade30112d4714f73ec8e3adb4072c0cc0d141a47734c20b345775b05c80afc`).
- **Sign**: Provided only 1 signature.
- **Execute**: Called `execTransaction`.
- **Result**: ✅ Expected Revert. The transaction failed with error `GS020` (Signatures data too short), confirming the multi-signature threshold rules are actively enforced.
