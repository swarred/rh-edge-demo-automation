#!/usr/bin/env bash
set -euo pipefail

CREDS_DIR="$(dirname "$0")/.creds"
mkdir -p "$CREDS_DIR"
chmod 700 "$CREDS_DIR"

echo ""
echo "RH Edge Demo — Credential Setup"
echo "================================"
echo ""

# ── Pull secret from OCP cluster ──────────────────────────────────────
echo "Step 1: Extracting pull secret from OCP cluster..."
if oc whoami &>/dev/null; then
    oc get secret pull-secret -n openshift-config \
       -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d \
       > "$CREDS_DIR/pull-secret.json"
    chmod 600 "$CREDS_DIR/pull-secret.json"
    echo "  ✓ Pull secret saved to .creds/pull-secret.json"
else
    echo "  ✗ Not logged in to OCP — run 'oc login' first"
    echo "    Or manually place pull-secret JSON at .creds/pull-secret.json"
fi

# ── Clean stale subscription-manager registration ─────────────────────
echo ""
echo "Step 2: Cleaning any stale subscription-manager profile..."
if sudo subscription-manager clean &>/dev/null; then
    echo "  ✓ Stale profile cleaned"
else
    echo "  (nothing to clean or permission denied — continuing)"
fi

# ── Red Hat Organization ID ───────────────────────────────────────────
echo ""
echo "Step 3: Red Hat Organization ID"
echo "  Find this at: console.redhat.com → (top-right account) → Subscriptions"
echo "  It is a numeric ID, e.g. 1234567"
echo ""
read -rp "  Enter your Organization ID: " ORG_ID
echo -n "$ORG_ID" > "$CREDS_DIR/rhsm-org.txt"
chmod 600 "$CREDS_DIR/rhsm-org.txt"
echo "  ✓ Org ID saved"

# ── Activation Key ────────────────────────────────────────────────────
echo ""
echo "Step 4: Red Hat Activation Key"
echo "  Create one at: console.redhat.com → Inventory → Activation Keys"
echo "  The key must have entitlements for:"
echo "    - Red Hat OpenShift Container Platform (for MicroShift)"
echo "    - Red Hat Enterprise Linux"
echo ""
read -rp "  Enter your Activation Key name: " ACT_KEY
echo -n "$ACT_KEY" > "$CREDS_DIR/rhsm-key.txt"
chmod 600 "$CREDS_DIR/rhsm-key.txt"
echo "  ✓ Activation key saved"

# ── Summary ───────────────────────────────────────────────────────────
echo ""
echo "All credentials saved to .creds/ (git-ignored)"
echo ""
echo "To build the bootc image, run:"
echo ""
echo "  sudo podman build \\"
echo "    --authfile $CREDS_DIR/pull-secret.json \\"
echo "    --secret id=rhsm-org,src=$CREDS_DIR/rhsm-org.txt \\"
echo "    --secret id=rhsm-key,src=$CREDS_DIR/rhsm-key.txt \\"
echo "    -t localhost/rh-edge-node:latest \\"
echo "    ../rh-edge-demo"
echo ""
echo "Or run: ansible-playbook site.yml --ask-become-pass"
echo ""
