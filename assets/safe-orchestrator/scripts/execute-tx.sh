#!/usr/bin/env bash
# execute-tx.sh
# Execute a Safe transaction once enough signatures are collected.
# Signatures must be sorted by signer address (ascending) — this script handles it.
#
# Usage:
#   Source environment variables then run:
#   bash scripts/execute-tx.sh
#
# Required env:
#   SAFE_ADDR      — the Safe proxy address
#   RPC_URL        — Pharos RPC endpoint
#   PRIVATE_KEY    — executor's private key (doesn't need to be an owner)
#   TX_TO          — destination address (from propose-tx.sh)
#   TX_VALUE       — ETH value in wei (from propose-tx.sh)
#   TX_DATA        — calldata hex (from propose-tx.sh)
#   TX_OPERATION   — 0 or 1 (from propose-tx.sh)
#   TX_NONCE       — Safe nonce used when proposing
#
# Signatures: provide as SIGNER1/SIG1, SIGNER2/SIG2, etc.
#   SIGNER1=0x... SIG1=0x...
#   SIGNER2=0x... SIG2=0x...
#   (continue for all collected signatures)

set -euo pipefail

: "${SAFE_ADDR:?Set SAFE_ADDR}"
: "${RPC_URL:?Set RPC_URL}"
: "${PRIVATE_KEY:?Set PRIVATE_KEY}"
: "${TX_TO:?Set TX_TO}"
: "${TX_VALUE:?Set TX_VALUE}"
: "${TX_DATA:?Set TX_DATA}"
: "${TX_OPERATION:?Set TX_OPERATION}"

SAFE_TX_GAS=0
BASE_GAS=0
GAS_PRICE_SAFE=0
GAS_TOKEN="0x0000000000000000000000000000000000000000"
REFUND_RECEIVER="0x0000000000000000000000000000000000000000"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Executing Safe Transaction"
echo "  Safe:      $SAFE_ADDR"
echo "  To:        $TX_TO"
echo "  Value:     $TX_VALUE"
echo "  Operation: $TX_OPERATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Collect and sort signatures ───────────────────────────────────
# Find all SIGNER/SIG pairs from environment
declare -A SIG_MAP

for var in $(env | grep '^SIGNER[0-9]' | sort | sed 's/=.*//'); do
  INDEX="${var#SIGNER}"
  SIGNER_ADDR="${!var}"
  SIG_VAR="SIG${INDEX}"
  SIG_VALUE="${!SIG_VAR:-}"

  if [ -n "$SIG_VALUE" ]; then
    # Normalize signer to lowercase for sorting
    SIGNER_LOWER=$(echo "$SIGNER_ADDR" | tr '[:upper:]' '[:lower:]')
    SIG_MAP["$SIGNER_LOWER"]="$SIG_VALUE"
    echo "  Collected sig from: $SIGNER_ADDR"
  fi
done

if [ ${#SIG_MAP[@]} -eq 0 ]; then
  echo "❌ No signatures found. Set SIGNER1/SIG1, SIGNER2/SIG2, etc."
  exit 1
fi

# ── Sort by signer address (ascending) and pack signatures ────────
echo ""
echo "Sorting and packing signatures..."
PACKED_SIGS="0x"

# Sort keys (signer addresses) alphabetically = ascending hex order
for SIGNER_ADDR in $(echo "${!SIG_MAP[@]}" | tr ' ' '\n' | sort); do
  SIG="${SIG_MAP[$SIGNER_ADDR]}"
  # Strip 0x prefix for packing
  SIG_CLEAN="${SIG#0x}"
  PACKED_SIGS="${PACKED_SIGS}${SIG_CLEAN}"
  echo "  + $SIGNER_ADDR"
done

echo "  Packed: ${PACKED_SIGS:0:20}...${PACKED_SIGS: -10}"

# ── Verify threshold ──────────────────────────────────────────────
THRESHOLD=$(cast call "$SAFE_ADDR" "getThreshold()(uint256)" --rpc-url "$RPC_URL")
SIG_COUNT=${#SIG_MAP[@]}

echo ""
echo "  Signatures collected: $SIG_COUNT"
echo "  Threshold required:   $THRESHOLD"

if [ "$SIG_COUNT" -lt "$THRESHOLD" ]; then
  echo "❌ Not enough signatures. Need $THRESHOLD, have $SIG_COUNT."
  exit 1
fi

echo "  ✅ Threshold met — executing..."

# ── Execute ───────────────────────────────────────────────────────
TX_HASH=$(cast send "$SAFE_ADDR" \
  "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)" \
  "$TX_TO" \
  "$TX_VALUE" \
  "$TX_DATA" \
  "$TX_OPERATION" \
  "$SAFE_TX_GAS" \
  "$BASE_GAS" \
  "$GAS_PRICE_SAFE" \
  "$GAS_TOKEN" \
  "$REFUND_RECEIVER" \
  "$PACKED_SIGS" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --json | jq -r '.transactionHash')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Transaction executed!"
echo "  Tx hash: $TX_HASH"
echo ""
echo "  View on explorer:"
CHAIN_ID=$(cast chain-id --rpc-url "$RPC_URL")
if [ "$CHAIN_ID" = "14853" ]; then
  echo "  https://pharosscan.xyz/tx/$TX_HASH"
elif [ "$CHAIN_ID" = "688688" ]; then
  echo "  https://testnet.pharosscan.xyz/tx/$TX_HASH"
else
  echo "  https://atlantic.pharosscan.xyz/tx/$TX_HASH"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
