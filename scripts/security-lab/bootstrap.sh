#!/usr/bin/env bash
set -euo pipefail

LAB_ROOT="${1:-/opt/security-lab}"

mkdir -p "$LAB_ROOT"/{web-scan,api-scan,recon,network-scan,automation,reports,logs,evidence,workspace}

echo "Created workspace: $LAB_ROOT"
echo "Next steps:"
echo "  1) Copy .env.example to $LAB_ROOT/.env and set values"
echo "  2) Copy allowlist.example.txt to $LAB_ROOT/allowlist.txt"
echo "  3) Start containers with docker compose"
