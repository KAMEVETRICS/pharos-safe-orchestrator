---
name: pharos-safe-orchestrator
description: >
  Pharos Safe Multisig Orchestrator Skill. Manages Gnosis Safe wallets on the Pharos Network via bash scripts and `cast`.
  Invoke whenever the user wants to deploy a new Safe multisig, check Safe status, propose a Safe transaction, sign a pending transaction, or execute a fully-signed Safe transaction. Supports multi-agent signature coordination.
version: 0.1.0
requires:
  anyBins:
  - bash
  - cast
---

# Pharos Safe Multisig Orchestrator Skill

Developer toolkit for managing Safe (Gnosis) multisigs natively via bash scripts. No intermediate contracts required.

## Prerequisites

1. **Install Foundry** (MANDATORY — MUST be done before ANY other action):
   - The Agent MUST first run `which cast` to check if Foundry is installed.
   - If `cast` is NOT found, install it:
     ```bash
     curl -L https://foundry.paradigm.xyz | bash
     source ~/.zshenv && foundryup
     cast --version
     ```
   - If installation fails, inform the user and STOP.
2. **Environment Setup**:
   - Private Key: `$PRIVATE_KEY`
   - Safe Address: `$SAFE_ADDR`

## Network Configuration & Contract Addresses

- **Testnet RPC URL**: `https://atlantic.dplabs-internal.com`
- **Mainnet RPC URL**: `https://rpc.pharos.xyz`

**Safe v1.4.1 Addresses (Deterministic across EVM)**:
- SafeProxyFactory: `0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67`
- SafeL2 Singleton: `0x29fcB43b46531BcA003ddC8FCB67FFE91900C762`
- CompatibilityFallbackHandler: `0xfd0732Dc9E303f09fCEf3a7388Ad10A83459Ec99`

## Command Templates

The following bash commands must be executed exactly as shown. **Do not search for external files.**

### 1. Deploy Safe
Deploys a new Gnosis Safe proxy on the Pharos Network.
```bash
OWNER1=<address1> OWNER2=<address2> THRESHOLD=<threshold> RPC_URL=<rpc_url> PRIVATE_KEY=$PRIVATE_KEY bash assets/safe-orchestrator/scripts/deploy-safe.sh
```

### 2. Status Check
Reads the current state of a Safe, including owners, threshold, nonce, and balances.
```bash
SAFE_ADDR=$SAFE_ADDR RPC_URL=<rpc_url> bash assets/safe-orchestrator/scripts/status.sh
```

### 3. Propose Transaction
Encodes a Safe transaction and computes its EIP-712 hash for signing. Does NOT submit to chain.
For token transfers, encode the ERC20 transfer calldata using `cast calldata "transfer(address,uint256)" <recipient> <amount_wei>` and set it as `DATA`.
```bash
SAFE_ADDR=$SAFE_ADDR TO=<destination_addr> VALUE=<eth_wei> DATA=<calldata_hex> RPC_URL=<rpc_url> bash assets/safe-orchestrator/scripts/propose-tx.sh
```
*(Save the output `SafeTx Hash` for the signing step).*

### 4. Sign Transaction
Signs a Safe transaction hash with a private key.
```bash
SAFE_TX_HASH=<safe_tx_hash> PRIVATE_KEY=$PRIVATE_KEY bash assets/safe-orchestrator/scripts/sign-tx.sh
```
*(Save the output signer address and `SIG` for the execute step).*

### 5. Execute Transaction
Executes a Safe transaction once enough signatures are collected (meets the threshold).
```bash
SAFE_ADDR=$SAFE_ADDR RPC_URL=<rpc_url> PRIVATE_KEY=$PRIVATE_KEY \
TX_TO=<to> TX_VALUE=<value> TX_DATA=<data> TX_OPERATION=<operation> \
SIGNER1=<signer1_addr> SIG1=<signature1> \
SIGNER2=<signer2_addr> SIG2=<signature2> \
bash assets/safe-orchestrator/scripts/execute-tx.sh
```

### 6. Add / Remove Owner / Change Threshold
These are management operations that go through the standard Propose → Sign → Execute flow. The `TO` address is the Safe itself, and `DATA` is the encoded management calldata:
```bash
# Add owner (and optionally update threshold)
DATA=$(cast calldata "addOwnerWithThreshold(address,uint256)" <new_owner> <new_threshold>)

# Remove owner
DATA=$(cast calldata "removeOwner(address,address,uint256)" <prev_owner> <owner_to_remove> <new_threshold>)

# Change threshold only
DATA=$(cast calldata "changeThreshold(uint256)" <new_threshold>)
```
Then run propose → sign → execute with `TO=$SAFE_ADDR` and the encoded `DATA`.

## Write Operation Pre-checks

For all operations requiring a private key (Deploy, Sign, Execute), the Agent MUST:
1. **Check Private Key**: Verify `$PRIVATE_KEY` is set.
2. **Confirm Network**: Explicitly confirm the network before executing.
3. **Validate Signatures**: Ensure `THRESHOLD` number of signatures have been collected before attempting `execute-tx.sh`.

## General Error Handling

| Error Signature | Handling |
|----------------|---------| 
| `invalid address` | Prompt to check address format |
| `GS020` | Signatures data too short (Threshold not met) |
| `GS026` | Invalid owner provided / Signature not matching owner |
| Command missing `PRIVATE_KEY` | Prompt user to set `$PRIVATE_KEY` |
