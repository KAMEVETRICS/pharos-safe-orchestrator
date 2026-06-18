# Pharos Safe Multisig Orchestrator Skill

![Bash](https://img.shields.io/badge/Bash-100%25-4EAA25)
![Pharos](https://img.shields.io/badge/Network-Pharos-blueviolet)
![Skill Engine](https://img.shields.io/badge/Pharos%20Skill%20Engine-v0.1.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

The Safe Orchestrator Skill is a developer toolkit for the Pharos blockchain, designed to allow AI agents (and human operators) to manage Gnosis Safe multisig wallets. It communicates directly with deployed Safe contracts via Foundry's `cast` and custom bash scripts, eliminating the need for an intermediate smart contract.

## Why this matters for Pharos + Agent Economy

- Multi-agent collaboration often requires shared treasuries or a multisig consensus before taking critical on-chain actions.
- This skill empowers groups of agents to vote on, sign, and orchestrate transactions securely, acting as decentralized, autonomous committees on the Pharos network.

## Installation

Agents and developers can easily install this skill into their Pharos Agent Centre setup:

```bash
npx skills add https://github.com/KAMEVETRICS/pharos-safe-orchestrator
```

## Prerequisites

1. **Foundry Installed**: This skill relies heavily on `cast`.
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   source ~/.zshenv && foundryup
   ```
2. **Private Key**: Required for proposing, signing, and executing transactions.
   ```bash
   export PRIVATE_KEY=0xYourPrivateKeyHere
   ```
3. **RPC URL**: Point to the Pharos testnet or mainnet.
   ```bash
   export RPC_URL=https://atlantic.dplabs-internal.com
   ```

## Agent Policy / Expected Behavior

This skill is designed to be invoked automatically by an AI agent acting as part of a multisig quorum:
- 🛑 **BLOCK**: Do not sign Safe transactions if the underlying transaction target/data is unsafe or violates the agent's predefined ethical/financial bounds.
- ⚠️ **WARN**: Alert co-signers if the execution gas limits are suspiciously high.
- ✅ **ALLOW**: Automatically sign periodic payout or administrative transactions that match an expected whitelist.

## Quickstart

Once the prerequisites are set, you can invoke the skill via an AI agent by using natural language:

**Example Agent Prompts:**
- "Deploy a 2-of-3 Safe with owners 0xAlice, 0xBob, and 0xCarol."
- "What's the balance and status of my Safe?"
- "Propose sending 100 USDC to 0xDave."
- "Sign the pending transaction."
- "We have enough signatures, execute the transaction."

## Documentation

- **[SKILL.md](./SKILL.md)**: The primary entry point for AI agents. Contains the Capability Index and general guidelines.
- **[Safe Orchestrator Operations](./references/safe-orchestrator.md)**: The detailed command templates for each supported action.
- **[Safe Contracts](./references/safe-contracts.md)**: Addresses and reference details for Safe singletons and factories.
- **[Tokens & Networks](./assets/)**: Address dictionaries for supported networks and tokens.
