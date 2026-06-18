#!/usr/bin/env bash
# deploy-safe.sh
# Deploy a new Gnosis Safe proxy on Pharos Network
#
# Usage:
#   OWNER1=0x... OWNER2=0x... OWNER3=0x... THRESHOLD=2 bash scripts/deploy-safe.sh
#
# Required env:
#   PRIVATE_KEY   — deployer/payer private key
#   RPC_URL       — Pharos RPC endpoint
#   OWNER1..N     — owner addresses
#   THRESHOLD     — required signatures (e.g. 2)
#
# Optional env:
#   SALT_NONCE    — for deterministic address (default: 0)

set -euo pipefail

# ── Validation ────────────────────────────────────────────────────
: "${PRIVATE_KEY:?Set PRIVATE_KEY}"
: "${RPC_URL:?Set RPC_URL}"
: "${THRESHOLD:?Set THRESHOLD}"

SALT_NONCE="${SALT_NONCE:-0}"

# ── Contract Addresses ────────────────────────────────────────────
FACTORY="0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67"
SINGLETON="0x29fcB43b46531BcA003ddC8FCB67FFE91900C762"  # SafeL2
FALLBACK="0xfd0732Dc9E303f09fCEf3a7388Ad10A83459Ec99"

# ── Build Owners Array ────────────────────────────────────────────
# Collect all OWNER* env variables into an array
OWNERS=()
for var in $(env | grep '^OWNER[0-9]' | sort | sed 's/=.*//'); do
  OWNERS+=("${!var}")
done

if [ ${#OWNERS[@]} -eq 0 ]; then
  echo "❌ No owner addresses found. Set OWNER1, OWNER2, etc."
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Deploying Gnosis Safe on Pharos"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Network:   $RPC_URL"
echo "  Owners:    ${OWNERS[*]}"
echo "  Threshold: $THRESHOLD of ${#OWNERS[@]}"
echo "  Salt:      $SALT_NONCE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Build owners array string for cast ───────────────────────────
OWNERS_JOINED=$(IFS=,; echo "${OWNERS[*]}")
OWNERS_ARR="[$OWNERS_JOINED]"

# ── Encode setup() calldata ───────────────────────────────────────
echo "Encoding setup calldata..."
INITIALIZER=$(cast calldata \
  "setup(address[],uint256,address,bytes,address,address,uint256,address)" \
  "$OWNERS_ARR" \
  "$THRESHOLD" \
  "0x0000000000000000000000000000000000000000" \
  "0x" \
  "$FALLBACK" \
  "0x0000000000000000000000000000000000000000" \
  0 \
  "0x0000000000000000000000000000000000000000"
)

echo "Initializer: $INITIALIZER"

# ── Deploy Safe Proxy ─────────────────────────────────────────────
echo ""
echo "Deploying Safe proxy..."
TX_HASH=$(cast send "$FACTORY" \
  "createProxyWithNonce(address,bytes,uint256)" \
  "$SINGLETON" \
  "$INITIALIZER" \
  "$SALT_NONCE" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --json | jq -r '.transactionHash')

echo "Transaction: $TX_HASH"

# ── Get deployed Safe address from logs ───────────────────────────
echo "Getting Safe address from receipt..."
sleep 2  # wait for indexing

SAFE_ADDR=$(cast receipt "$TX_HASH" \
  --rpc-url "$RPC_URL" \
  --json | jq -r '.logs[0].topics[1]' | \
  sed 's/0x000000000000000000000000/0x/')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Safe deployed successfully!"
echo "  Safe address: $SAFE_ADDR"
echo ""
echo "  Run: export SAFE_ADDR=$SAFE_ADDR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
