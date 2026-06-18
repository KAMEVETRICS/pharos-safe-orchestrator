#!/usr/bin/env bash
# status.sh
# Read the current state of a Gnosis Safe on Pharos.
# Read-only — no private key needed.
#
# Usage:
#   SAFE_ADDR=0x... RPC_URL=https://... bash scripts/status.sh
#
# Optional:
#   TOKEN_ADDRS — comma-separated list of ERC20 addresses to check balances

set -euo pipefail

: "${SAFE_ADDR:?Set SAFE_ADDR}"
: "${RPC_URL:?Set RPC_URL}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Safe Status: $SAFE_ADDR"
echo "  Network:     $RPC_URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Owners ────────────────────────────────────────────────────────
echo ""
echo "👥 Owners:"
cast call "$SAFE_ADDR" \
  "getOwners()(address[])" \
  --rpc-url "$RPC_URL"

# ── Threshold ─────────────────────────────────────────────────────
echo ""
THRESHOLD=$(cast call "$SAFE_ADDR" \
  "getThreshold()(uint256)" \
  --rpc-url "$RPC_URL")
echo "🔐 Threshold: $THRESHOLD required signatures"

# ── Nonce ─────────────────────────────────────────────────────────
echo ""
NONCE=$(cast call "$SAFE_ADDR" \
  "nonce()(uint256)" \
  --rpc-url "$RPC_URL")
echo "📋 Current nonce: $NONCE"

# ── Native Balance ─────────────────────────────────────────
echo ""
BALANCE=$(cast balance "$SAFE_ADDR" --rpc-url "$RPC_URL")
BALANCE_ETH=$(cast --from-wei "$BALANCE")
CHAIN_ID=$(cast chain-id --rpc-url "$RPC_URL" 2>/dev/null || echo "0")
if [ "$CHAIN_ID" = "1672" ]; then NATIVE="PROS"; else NATIVE="PHRS"; fi
echo "💰 Native ($NATIVE): $BALANCE_ETH $NATIVE"

# ── Token Balances (optional) ─────────────────────────────────────
if [ -n "${TOKEN_ADDRS:-}" ]; then
  echo ""
  echo "🪙 Token Balances:"
  IFS=',' read -ra TOKENS <<< "$TOKEN_ADDRS"
  for TOKEN in "${TOKENS[@]}"; do
    TOKEN=$(echo "$TOKEN" | tr -d ' ')
    SYMBOL=$(cast call "$TOKEN" "symbol()(string)" --rpc-url "$RPC_URL" 2>/dev/null || echo "UNKNOWN")
    DECIMALS=$(cast call "$TOKEN" "decimals()(uint8)" --rpc-url "$RPC_URL" 2>/dev/null || echo "18")
    RAW_BAL=$(cast call "$TOKEN" "balanceOf(address)(uint256)" "$SAFE_ADDR" --rpc-url "$RPC_URL")
    HUMAN_BAL=$(cast --from-unit "$RAW_BAL" "$DECIMALS" 2>/dev/null || echo "$RAW_BAL (raw)")
    echo "  $SYMBOL ($TOKEN): $HUMAN_BAL"
  done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
