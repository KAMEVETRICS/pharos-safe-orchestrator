#!/usr/bin/env bash
# sign-tx.sh
# Sign a Safe transaction hash with your private key.
# Each signer runs this independently; signatures are collected for execution.
#
# Usage:
#   SAFE_TX_HASH=0x... PRIVATE_KEY=0x... bash scripts/sign-tx.sh
#
# Required env:
#   SAFE_TX_HASH  — from propose-tx.sh output
#   PRIVATE_KEY   — this signer's private key

set -euo pipefail

: "${SAFE_TX_HASH:?Set SAFE_TX_HASH (from propose-tx.sh)}"
: "${PRIVATE_KEY:?Set PRIVATE_KEY}"

# Derive signer address from private key
SIGNER=$(cast wallet address --private-key "$PRIVATE_KEY")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Signing Safe Transaction"
echo "  Signer:        $SIGNER"
echo "  SafeTx Hash:   $SAFE_TX_HASH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Sign the hash directly (eth_sign style — Safe accepts this)
# Note: cast wallet sign signs with personal_sign prefix by default
# For Safe EIP-712, sign the raw hash without prefix using --no-hash
SIGNATURE=$(cast wallet sign \
  --private-key "$PRIVATE_KEY" \
  --no-hash \
  "$SAFE_TX_HASH")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Signature from $SIGNER:"
echo "  $SIGNATURE"
echo ""
echo "  Send this to the executor (along with your signer address)."
echo "  Executor collects all signatures, then runs execute-tx.sh"
echo ""
echo "  Format for executor:"
echo "  SIGNER=$SIGNER"
echo "  SIG=$SIGNATURE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
