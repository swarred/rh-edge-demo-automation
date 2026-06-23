#!/usr/bin/env bash
set -euo pipefail

CREDS_DIR="$(dirname "$0")/.creds"
mkdir -p "$CREDS_DIR"
chmod 700 "$CREDS_DIR"

echo ""
echo "RH Edge Demo — Credential Setup"
echo "================================"
echo ""

# ── Step 1: Pull secret from OCP cluster ──────────────────────────────
echo "Step 1: Extracting pull secret from OCP cluster..."
if oc whoami &>/dev/null; then
    oc get secret pull-secret -n openshift-config \
       -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d \
       > "$CREDS_DIR/pull-secret.json"
    chmod 600 "$CREDS_DIR/pull-secret.json"
    echo "  ✓ Pull secret saved to .creds/pull-secret.json"
else
    echo "  ✗ Not logged in to OCP. Run 'oc login' first, then re-run this script."
    exit 1
fi

# ── Step 2: Clean stale subscription-manager profile ──────────────────
echo ""
echo "Step 2: Cleaning any stale subscription-manager profile..."
sudo subscription-manager clean 2>/dev/null && echo "  ✓ Done" || echo "  (skipped)"

# ── Step 3: Red Hat account credentials ───────────────────────────────
echo ""
echo "Step 3: Red Hat account credentials"
echo "  These are your login credentials for access.redhat.com / console.redhat.com"
echo "  They are used only during the container build to install MicroShift RPMs."
echo "  They are NEVER stored in the image (subscription-manager unregisters"
echo "  inside the build before dnf clean all)."
echo ""
read -rp "  Red Hat username (email): " RH_USER
read -rsp "  Red Hat password: " RH_PASS
echo ""

echo -n "$RH_USER" > "$CREDS_DIR/rhsm-user.txt"
echo -n "$RH_PASS" > "$CREDS_DIR/rhsm-pass.txt"
chmod 600 "$CREDS_DIR/rhsm-user.txt" "$CREDS_DIR/rhsm-pass.txt"
echo "  ✓ Credentials saved to .creds/ (never committed to git)"

# ── Summary ───────────────────────────────────────────────────────────
DEMO_DIR="$(dirname "$0")/../rh-edge-demo"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Setup complete. To build the bootc image:"
echo ""
echo "  sudo podman build \\"
echo "    --authfile $CREDS_DIR/pull-secret.json \\"
echo "    --secret id=rhsm-user,src=$CREDS_DIR/rhsm-user.txt \\"
echo "    --secret id=rhsm-pass,src=$CREDS_DIR/rhsm-pass.txt \\"
echo "    -t localhost/rh-edge-node:latest \\"
echo "    $DEMO_DIR"
echo ""
echo "Or run the full deploy:"
echo "  ansible-playbook site.yml --ask-become-pass"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
