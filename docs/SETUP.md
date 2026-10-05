# Setup and launch instructions (configuration bundle)

How each machine is configured. Domain `team67.test`. The day-of order, evidence commands and
troubleshooting are in `RUNBOOK.md`.

| Node | Member | Role | Runs |
|---|---|---|---|
| Node 1 | Tathagat | DNS + edge (nginx, TLS, load balancer) | dnsmasq 2.93, nginx 1.31.6, OpenSSL 3 (Homebrew) |
| Node 2 | MS Thejas | Backend A + client | Python 3 backend on 3001, browser, curl |
| Node 3 | Garv Verma | Backend B + client | Python 3 backend on 3002, curl, Wireshark |

All commands run from the repo folder (`cn-project/`) unless stated.

## 0. Every Mac
- Join the same Wi-Fi. In System Settings → Wi-Fi → (network) → Details, set **Private Wi-Fi address: Fixed**
  so the MAC and IP stay the same all day.
- Network service name: `networksetup -listallnetworkservices` (normally `Wi-Fi`; use yours in the commands below).
- If the macOS firewall is on (System Settings → Network → Firewall), click **Allow** when asked about
  incoming connections for `python3` (MS Thejas, Garv Verma) or `dnsmasq`/`nginx` (Tathagat).
- Keep the Mac awake during the session: `caffeinate -dims` in a spare terminal tab.

## 1. Node 1 (Tathagat): IPs, DNS, certificates, edge

**Set the real IPs** (re-run any time an IP changes; it also syntax-checks dnsmasq):
```bash
scripts/set-ips.sh <TATHAGAT_IP> <THEJAS_IP> <GARV_IP>
```
It rewrites `listen-address` and both `host-record` lines in `dns/dnsmasq.conf`, and the two `listen`
lines and two upstream `server` lines in `nginx/team67.conf`.

**DNS (dnsmasq).** Port 53 needs root. Runs in the foreground in its own tab; every query is printed and saved:
```bash
sudo /opt/homebrew/sbin/dnsmasq -C dns/dnsmasq.conf 2>&1 | tee -a logs/dnsmasq.log
```
Stop with Ctrl+C. Check from Node 1: `dig @<TATHAGAT_IP> app.team67.test +short` → `<TATHAGAT_IP>`.
Config summary: answers `app`/`api.team67.test` itself (`local=/team67.test/`, TTL 60), forwards all other
names to 8.8.8.8 / 1.1.1.1, ignores `/etc/hosts`, logs every query.

**Certificates.** Generated once with `certs/make-certs.sh` (OpenSSL 3 from Homebrew):
1. Root CA "Team67 Local Root CA" (RSA 2048, 825 days, `CA:TRUE`, keyCertSign/cRLSign).
2. Server key + CSR for `CN=app.team67.test`, signed by the CA (397 days, serverAuth,
   SAN `DNS:app.team67.test, DNS:api.team67.test`, no IP SANs).
3. `openssl verify` checks the chain.
Only `certs/rootCA.pem` is given to the clients. `rootCA.key` and `team67.key` never leave Node 1
(git-ignored, mode 600). The certificate contains no IPs, so it does not change when IPs change.

**Edge (nginx).** Ports 80/443 need root:
```bash
sudo nginx -t -p "$PWD/" -c nginx/team67.conf            # test
sudo nginx    -p "$PWD/" -c nginx/team67.conf            # start
sudo nginx    -p "$PWD/" -c nginx/team67.conf -s reload  # after a config change
sudo nginx    -p "$PWD/" -c nginx/team67.conf -s quit    # stop
```
Config summary: upstream `team67_backends` = MS Thejas:3001 + Garv Verma:3002, round-robin, `max_fails=1 fail_timeout=10s`;
port 80 → `301` to HTTPS; port 443 TLS 1.2/1.3 + HTTP/2 with our certificate; `proxy_next_upstream error timeout
http_502 http_503`, `proxy_connect_timeout 5s`; access log with `upstream=` in `logs/nginx-access.log`,
errors in `logs/nginx-error.log`.

Node 1 does not change its own DNS settings and is not a test client.

## 2. Node 2 (MS Thejas) and Node 3 (Garv Verma): backends
```bash
mkdir -p ~/team67-evidence/C-backends
BACKEND=A PORT=3001 python3 backend/server.py 2>&1 | tee -a ~/team67-evidence/C-backends/C3-thejas-backend-log.txt   # MS Thejas
BACKEND=B PORT=3002 python3 backend/server.py 2>&1 | tee -a ~/team67-evidence/C-backends/C3-garv-backend-log.txt     # Garv Verma
```
Stop with Ctrl+C. Binds `0.0.0.0` (all interfaces) so Node 1 can reach it. Endpoints:

| Endpoint | Response | Cache-Control |
|---|---|---|
| `GET /` | `{"service","backend","host","message":"running"}` | none |
| `GET /api/status` | `{"backend":"A","status":"ok","time":…}` | `no-store` |
| `GET /api/cached` | Same body on A and B, strong ETag, `304` on `If-None-Match` | `public, max-age=60` |

Every response has `X-Backend: A` or `B`. Every request is logged with `from=<peer IP>`.

## 3. Node 2 and Node 3: clients
**Trust the team CA** (once; can be done before Monday):
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain certs/rootCA.pem
```
**Use the team DNS server:**
```bash
sudo networksetup -setdnsservers Wi-Fi <TATHAGAT_IP>
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
dig app.team67.test +short        # <TATHAGAT_IP>
dig google.com +short             # still resolves (forwarded)
```
Always open the service by name: `https://app.team67.test/...`. Never use `-k`.

## 4. End of session: put everything back
```bash
sudo networksetup -setdnsservers Wi-Fi Empty                      # MS Thejas, Garv Verma (or their internet DNS breaks when Node 1 leaves)
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder     # MS Thejas, Garv Verma
sudo nginx -p "$PWD/" -c nginx/team67.conf -s quit                # Tathagat; Ctrl+C the dnsmasq tab
```
Backends: Ctrl+C. Optional, to remove the CA later:
`sudo security delete-certificate -c "Team67 Local Root CA" /Library/Keychains/System.keychain`.
