#!/usr/bin/env bash
# propose-tx.sh
# Encode a Safe transaction and compute its EIP-712 hash for signing.
# Does NOT submit to chain — outputs the hash that signers need to sign.
#
# Usage:
#   SAFE_ADDR=0x... TO=0x... VALUE=0 DATA=0x RPC_URL=https://... bash scripts/propose-tx.sh
#
# Required env:
#   SAFE_ADDR   — the Safe proxy address
#   RPC_URL     — Pharos RPC endpoint
#   TO          — destination address
#
# Optional env:
#   VALUE       — ETH value in wei (default: 0)
#   DATA        — calldata hex (default: 0x)
#   OPERATION   — 0=CALL, 1=DELEGATECALL (default: 0)
#
# For ERC20 transfers, set DATA to the encoded transfer calldata:
#   DATA=$(cast calldata "transfer(address,uint256)" $RECIPIENT $AMOUNT_WEI)

set -euo pipefail

: "${SAFE_ADDR:?Set SAFE_ADDR}"
: "${RPC_URL:?Set RPC_URL}"
: "${TO:?Set TO (destination address)}"

VALUE="${VALUE:-0}"
DATA="${DATA:-0x}"
OPERATION="${OPERATION:-0}"
SAFE_TX_GAS="${SAFE_TX_GAS:-0}"
BASE_GAS="${BASE_GAS:-0}"
GAS_PRICE="${GAS_PRICE:-0}"
GAS_TOKEN="${GAS_TOKEN:-0x0000000000000000000000000000000000000000}"
REFUND_RECEIVER="${REFUND_RECEIVER:-0x0000000000000000000000000000000000000000}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Proposing Safe Transaction"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Read current nonce ────────────────────────────────────────────
NONCE=$(cast call "$SAFE_ADDR" "nonce()(uint256)" --rpc-url "$RPC_URL")
echo "  Safe:      $SAFE_ADDR"
echo "  To:        $TO"
echo "  Value:     $VALUE wei"
echo "  Data:      $DATA"
echo "  Operation: $OPERATION ($([ "$OPERATION" = "0" ] && echo "CALL" || echo "DELEGATECALL"))"
echo "  Nonce:     $NONCE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Compute Safe transaction hash ────────────────────────────────
echo ""
echo "Computing SafeTx hash..."
SAFE_TX_HASH=$(cast call "$SAFE_ADDR" \
  "getTransactionHash(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,uint256)(bytes32)" \
  "$TO" \
  "$VALUE" \
  "$DATA" \
  "$OPERATION" \
  "$SAFE_TX_GAS" \
  "$BASE_GAS" \
  "$GAS_PRICE" \
  "$GAS_TOKEN" \
  "$REFUND_RECEIVER" \
  "$NONCE" \
  --rpc-url "$RPC_URL")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ SafeTx Hash:"
echo "  $SAFE_TX_HASH"
echo ""
echo "  Share this hash with all required signers."
echo "  Each signer runs: SAFE_TX_HASH=$SAFE_TX_HASH bash scripts/sign-tx.sh"
echo ""
echo "  Save transaction parameters for execution:"
echo "  export SAFE_TX_HASH=$SAFE_TX_HASH"
echo "  export TX_TO=$TO"
echo "  export TX_VALUE=$VALUE"
echo "  export TX_DATA=$DATA"
echo "  export TX_OPERATION=$OPERATION"
echo "  export TX_NONCE=$NONCE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
