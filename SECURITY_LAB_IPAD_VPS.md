# iPad + VPS Security Lab Rollout (Authorized Testing Only)

> ⚠️ **Legal notice**: Run scans only against systems you own or have explicit written authorization to test.

This guide implements an iPad-first workflow where the iPad is the control plane and the VPS runs all heavy workloads.

## 1) Phase order (recommended)

1. **Secure access baseline**
   - Ubuntu 24.04 LTS VPS
   - Docker + Docker Compose plugin
   - UFW firewall + fail2ban + unattended security updates
   - Tailscale or WireGuard, SSH key-only access, MFA enabled

2. **Create isolated workspaces**
   - `web-scan`, `api-scan`, `recon`, `network-scan`, `automation`, `reports`, `logs`, `evidence`

3. **Deploy tool runtime**
   - Containerized services via `/scripts/security-lab/docker-compose.yml`
   - One command profiles via `/scripts/security-lab/run-profile.sh`

4. **Enable iPad-first operations**
   - iPad apps: Tailscale, Blink Shell (or equivalent), Working Copy, browser
   - Launch profiles remotely over SSH from iPad shortcuts/snippets

5. **Guardrails (mandatory)**
   - Target allowlist (`allowlist.txt`)
   - Explicit authorization acknowledgement (`LEGAL_ACKNOWLEDGEMENT`)
   - Rate limits and concurrency limits
   - Audit log trail in `logs/audit.log`

6. **Reporting + scale**
   - Store JSON output in `reports/` and supporting artifacts in `evidence/`
   - Start with one authorized pilot target, tune noise, then automate

## 2) Quick start

```bash
cd /home/runner/work/cf-server-monitor3/cf-server-monitor3
chmod +x scripts/security-lab/bootstrap.sh scripts/security-lab/run-profile.sh
scripts/security-lab/bootstrap.sh /opt/security-lab
cd /opt/security-lab
cp /home/runner/work/cf-server-monitor3/cf-server-monitor3/scripts/security-lab/.env.example .env
cp /home/runner/work/cf-server-monitor3/cf-server-monitor3/scripts/security-lab/allowlist.example.txt allowlist.txt
```

Edit `.env` and `allowlist.txt`, then start services:

```bash
docker compose -f /home/runner/work/cf-server-monitor3/cf-server-monitor3/scripts/security-lab/docker-compose.yml --env-file .env up -d
```

Run a guarded profile:

```bash
LEGAL_ACKNOWLEDGEMENT=I_HAVE_AUTHORIZATION \
/home/runner/work/cf-server-monitor3/cf-server-monitor3/scripts/security-lab/run-profile.sh web https://example.com /opt/security-lab
```

## 3) iPad workflow

1. Connect to your VPS over Tailscale/WireGuard.
2. Use Blink Shell to SSH into VPS.
3. Launch one of the profiles (`web`, `api`, `recon`) with `run-profile.sh`.
4. Download results from `/opt/security-lab/reports` using your preferred Git/files workflow.

## 4) Output standard (recommended)

Each finding should include:
- Severity
- Evidence
- Reproduction steps
- Impact
- Remediation
- Owner

The profile runner stores timestamped JSONL audit records and report artifacts for traceability.
