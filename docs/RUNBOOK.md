# Runbook: Monday session (all three together) + troubleshooting

Goal: build the live system on three Macs and capture every piece of evidence in about 4 hours.
Every evidence command is wrapped in `scripts/rec.sh`, which saves the exact command and its unedited
output (with time, Mac and IP) under `~/team67-evidence/<file>`. Never edit those files by hand.

Replace `<T>`, `<J>`, `<G>` with the real IPs of Tathagat, MS Thejas and Garv Verma (from step 1).
`<name>` = `tathagat`, `thejas` or `garv`. MS Thejas's and Garv Verma's personal sheets list only their own lines.

**Before arriving:** repo unzipped on all three Macs; CA trusted on MS Thejas's and Garv Verma's Macs; Wireshark
installed on Garv Verma's; chargers. Open the repo folder in a terminal; run `caffeinate -dims` in a spare tab.

## Step 1 · LAN (Task A) · 20–30 min · everyone
```bash
scripts/rec.sh A-lan/A1-<name>-netinfo.txt 'ipconfig getifaddr en0; ipconfig getoption en0 subnet_mask; route -n get default | grep -E "gateway|interface"; ifconfig en0 | grep -E "ether|inet "'
```
If the header line shows an interface other than `en0`, re-run with that interface. Say your IP aloud; Tathagat
writes all three down. Then each person pings the other two:
```bash
scripts/rec.sh A-lan/A2-<name>-ping.txt 'ping -c 3 <other IP 1>; ping -c 3 <other IP 2>'
```
Expect 0% loss and TTL 64 (same subnet, no router hop). If pings fail, the Wi-Fi isolates clients: switch
everyone to one phone hotspot and redo step 1.

## Step 2 · Configs (Tathagat) · 5 min
```bash
scripts/rec.sh B-dns/B1-tathagat-set-ips.txt 'scripts/set-ips.sh <T> <J> <G>'
```
Expect the rewritten lines and `dnsmasq: syntax check OK.`

## Step 3 · DNS (Task B) · 20–30 min
Tathagat, new tab, leave running:
```bash
sudo /opt/homebrew/sbin/dnsmasq -C dns/dnsmasq.conf 2>&1 | tee -a logs/dnsmasq.log
```
Tathagat:
```bash
scripts/rec.sh B-dns/B2-tathagat-dig-on-server.txt 'dig @<T> app.team67.test'
```
Garv Verma (asks our server directly, before changing any setting):
```bash
scripts/rec.sh B-dns/B3-garv-dig-team-server.txt 'dig @<T> app.team67.test'
```
MS Thejas and Garv Verma: point the Mac at the team DNS, then resolve with the normal resolver:
```bash
scripts/rec.sh B-dns/B4-<name>-client-resolver.txt 'sudo networksetup -setdnsservers Wi-Fi <T>; networksetup -getdnsservers Wi-Fi; sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; dig app.team67.test; nslookup app.team67.test; dig +short api.team67.test'
```
Expect `ANSWER SECTION: app.team67.test. 60 IN A <T>` and `;; SERVER: <T>#53`. Also take a screenshot of
System Settings → Wi-Fi → Details → DNS → save as `B4-<name>-dns-settings.png`.
Garv Verma:
```bash
scripts/rec.sh B-dns/B5-garv-forwarding.txt 'dig +short google.com'
```
Tathagat (the server saw the queries from both clients):
```bash
scripts/rec.sh B-dns/B6-tathagat-query-log.txt 'grep -E "team67|google" logs/dnsmasq.log | tail -n 25'
```

## Step 4 · Backends (Task C) · 15 min
MS Thejas, new tab, leave running:
```bash
mkdir -p ~/team67-evidence/C-backends && BACKEND=A PORT=3001 python3 backend/server.py 2>&1 | tee -a ~/team67-evidence/C-backends/C3-thejas-backend-log.txt
```
Garv Verma, new tab, leave running:
```bash
mkdir -p ~/team67-evidence/C-backends && BACKEND=B PORT=3002 python3 backend/server.py 2>&1 | tee -a ~/team67-evidence/C-backends/C3-garv-backend-log.txt
```
MS Thejas / Garv Verma (port 3001 / 3002):
```bash
scripts/rec.sh C-backends/C1-<name>-listening.txt 'lsof -nP -iTCP:<3001 or 3002> -sTCP:LISTEN'
```
Expect `*:3001` / `*:3002` (all interfaces). Tathagat (the edge reaching each backend directly):
```bash
scripts/rec.sh C-backends/C2-tathagat-direct-backends.txt 'curl -si http://<J>:3001/; echo; curl -si http://<J>:3001/api/status; echo; curl -si http://<G>:3002/api/status'
```

## Step 5 · Edge + load balancing (Task D) · 15–20 min
Tathagat:
```bash
scripts/rec.sh D-loadbalancer/D1-tathagat-nginx-test.txt 'sudo nginx -t -p "$PWD/" -c nginx/team67.conf'
sudo nginx -p "$PWD/" -c nginx/team67.conf
```
Garv Verma (by name only):
```bash
scripts/rec.sh D-loadbalancer/D2-garv-round-robin.txt 'for i in 1 2 3 4 5 6; do curl -si https://app.team67.test/api/status | grep -i "^x-backend"; done'
```
Expect A and B alternating. Tathagat (the edge's own record of which backend served each request):
```bash
scripts/rec.sh D-loadbalancer/D3-tathagat-access-log.txt 'tail -n 8 logs/nginx-access.log'
```
The backend tabs on MS Thejas's and Garv Verma's Macs now show `from=<T>`: requests come from the edge, never from the client.

## Step 6 · HTTPS / TLS (Task E) · 15–20 min
Tathagat:
```bash
scripts/rec.sh E-tls/E1-tathagat-certificate.txt 'O="$(brew --prefix openssl@3)/bin/openssl"; $O verify -CAfile certs/rootCA.pem certs/team67.crt; $O x509 -in certs/team67.crt -noout -subject -issuer -dates -ext subjectAltName'
```
MS Thejas and Garv Verma (the Mac's own trust store accepts our certificate for this name):
```bash
scripts/rec.sh E-tls/E2-<name>-system-trust.txt 'security verify-cert -c certs/team67.crt -p ssl -s app.team67.test'
scripts/rec.sh E-tls/E3-<name>-https.txt 'curl -si https://app.team67.test/api/status'
```
Expect `...certificate verification successful.` and `HTTP/2 200` with no `-k`. MS Thejas: open
`https://app.team67.test` in Safari/Chrome → screenshots `E4-thejas-browser-padlock.png` and
`E4-thejas-certificate-viewer.png` (issued to app.team67.test by Team67 Local Root CA), plus Keychain Access
showing the CA as trusted → `E2-thejas-keychain.png`.
Garv Verma:
```bash
scripts/rec.sh E-tls/E5-garv-http-versions.txt 'curl -sI --http1.1 https://app.team67.test/api/status | head -1; curl -sI --http2 https://app.team67.test/api/status | head -1'
scripts/rec.sh E-tls/E6-garv-http-redirect.txt 'curl -sI http://app.team67.test/api/status'
```
Expect `HTTP/1.1 200 OK` / `HTTP/2 200`, then `301` with `Location: https://app.team67.test/api/status`.

## Step 7 · Caching (Task F) · 10 min · MS Thejas
```bash
scripts/rec.sh F-caching/F1-thejas-cache-headers.txt 'curl -sI https://app.team67.test/api/cached'
scripts/rec.sh F-caching/F2-thejas-conditional-304.txt 'E=$(curl -sI https://app.team67.test/api/cached | grep -i "^etag" | cut -d" " -f2 | tr -d "\r"); echo "ETag received: $E"; curl -sI -H "If-None-Match: $E" https://app.team67.test/api/cached'
```
Expect `cache-control: public, max-age=60` + `etag`, then `HTTP/2 304` (note which backend sent each: the
ETag is the same on both). Fresh cache hit: open `https://app.team67.test/`, DevTools → Network, in the Console
run `fetch('/api/cached')` twice → second row shows "(disk cache)" → screenshot `F3-thejas-devtools-disk-cache.png`.

## Step 8 · Packet capture (Task G) · 30–45 min · Garv Verma
Follow `docs/SHEET-GARV.md` §Wireshark. Output: `G-wireshark/` pcapng files, `G1-garv-curl-verbose.txt`,
screenshots, and the filled-in `G-packet-index.md`.

## Step 9 · Failure demonstrations (spec §6.3) · 30–45 min
**H1 Wrong DNS server (Garv Verma):**
```bash
scripts/rec.sh H-failures/H1-garv-wrong-dns-server.txt 'sudo networksetup -setdnsservers Wi-Fi 8.8.8.8; sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; dig app.team67.test; curl -sS https://app.team67.test/api/status; ping -c 2 <T>; curl -s --resolve app.team67.test:443:<T> https://app.team67.test/api/status'
scripts/rec.sh H-failures/H1-garv-restore.txt 'sudo networksetup -setdnsservers Wi-Fi <T>; sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; dig +short app.team67.test'
```
Expect NXDOMAIN from 8.8.8.8 and `Could not resolve host`, yet ping and `--resolve` work: DNS failed, IP did not.

**H2 Record points to the wrong IP (Tathagat edits, Garv Verma observes):** Tathagat sets only the `app` record to
MS Thejas's IP, then restarts dnsmasq (Ctrl+C, start again):
```bash
scripts/rec.sh H-failures/H2-tathagat-wrong-record.txt 'sed -i "" -E "s/^(host-record=app\.team67\.test,)[0-9.]+/\1<J>/" dns/dnsmasq.conf; grep ^host-record dns/dnsmasq.conf'
```
Garv Verma:
```bash
scripts/rec.sh H-failures/H2-garv-wrong-record.txt 'sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; dig +short app.team67.test; curl -sS https://app.team67.test/api/status; echo; curl -sS https://api.team67.test/api/status'
```
Expect app → `<J>` and `Failed to connect ... port 443`, while api.team67.test still works. Restore:
Tathagat `scripts/set-ips.sh <T> <J> <G>`, restart dnsmasq; Garv Verma flushes the cache and checks `dig +short app.team67.test`.

**H3 One backend stopped + recovery:** MS Thejas presses Ctrl+C in the backend tab. Garv Verma:
```bash
scripts/rec.sh H-failures/H3-garv-one-backend-down.txt 'for i in 1 2 3 4 5 6; do curl -si https://app.team67.test/api/status | grep -iE "^HTTP|^x-backend"; done'
```
Tathagat:
```bash
scripts/rec.sh H-failures/H3-tathagat-nginx-error-log.txt 'tail -n 5 logs/nginx-error.log'
```
MS Thejas restarts the backend (same command as step 4). Wait 15 s (fail_timeout is 10 s). Garv Verma:
```bash
scripts/rec.sh H-failures/H3r-garv-recovery.txt 'for i in 1 2 3 4 5 6; do curl -si https://app.team67.test/api/status | grep -i "^x-backend"; done'
```
**H4 Both backends stopped:** MS Thejas and Garv Verma Ctrl+C both backends. Garv Verma:
```bash
scripts/rec.sh H-failures/H4-garv-both-backends-down.txt 'dig +short app.team67.test; curl -svi https://app.team67.test/api/status 2>&1 | grep -iE "SSL connection|verify|^< HTTP|^< server|x-backend"'
```
Expect TLS OK, `HTTP/2 502` from nginx, no `x-backend`. Restart both backends.

**H5 Wrong destination port (Garv Verma):**
```bash
scripts/rec.sh H-failures/H5-garv-wrong-port.txt 'nc -vz -G 3 <T> 443; nc -vz -G 3 <T> 8443; curl -sS https://app.team67.test:8443/api/status'
```
Expect 443 succeeded, 8443 refused: the IP picks the machine, the port picks the service.

## Step 10 · Collect evidence + docs · 30–45 min
1. MS Thejas and Garv Verma: rename `~/team67-evidence` to `team67-evidence-thejas` / `-garv` and AirDrop it to Tathagat.
2. Tathagat merges everything into the repo (file names never collide; each contains the owner's name):
   ```bash
   rsync -a ~/team67-evidence/ evidence/ && rsync -a ~/Downloads/team67-evidence-thejas/ evidence/ && rsync -a ~/Downloads/team67-evidence-garv/ evidence/
   ```
3. Fill the IP inventory in `docs/ARCHITECTURE.md` and the IPs in `docs/topology.svg` from `evidence/A-lan/`.
4. Tick every row in `evidence/INDEX.md`; check that each file exists.

## Step 11 · Rehearsal · 30 min
Run the demo sequence in `docs/VIVA.md` once, end to end, each person presenting their part.

## End of the day
Everything in `docs/SETUP.md` §4. Most important: MS Thejas and Garv Verma must run
`sudo networksetup -setdnsservers Wi-Fi Empty`, or their DNS fails once Tathagat's Mac leaves.

---

## If an IP changes (DHCP)

| Whose IP changed | Fix |
|---|---|
| Tathagat | `scripts/set-ips.sh <T> <J> <G>` → restart dnsmasq → `sudo nginx -p "$PWD/" -c nginx/team67.conf -s quit` then start again (listen address changed). Clients: `sudo networksetup -setdnsservers Wi-Fi <new T>` and flush the cache. |
| MS Thejas or Garv Verma | `scripts/set-ips.sh <T> <J> <G>` → `sudo nginx -t -p "$PWD/" -c nginx/team67.conf && sudo nginx -p "$PWD/" -c nginx/team67.conf -s reload` |

Flush a client's DNS cache: `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`.

## Something fails: go layer by layer (also the method for the faculty-injected fault)
| # | Check (from a client) | Bad result means |
|---|---|---|
| 1 | `dig app.team67.test` | No answer / NXDOMAIN / wrong IP / wrong `SERVER` → DNS: dnsmasq stopped, wrong record, or the client's DNS setting |
| 2 | `ping -c 2 <T>` | No reply → network: different Wi-Fi, Mac asleep, client isolation |
| 3 | `nc -vz <T> 443` | Refused → nginx not running / listening on an old IP |
| 4 | `curl -v https://app.team67.test/` | Certificate error → CA not trusted, wrong name, or expired cert |
| 5 | HTTP `502` / `504` | Backends: stopped, wrong IP/port in the upstream, firewall on the backend Mac |
| 6 | Wrong body / header | Application: backend code or env vars (`BACKEND`, `PORT`) |
