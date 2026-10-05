# Evidence index

Every `.txt` file was produced by `scripts/rec.sh` on the named member's Mac: each entry starts with the
capture time, user@host and that Mac's IP, then the exact command, its unedited output and its exit code.
Screenshots and `.pcapng` files come from the same session. Nothing in this folder is typed by hand except
this index and `G-wireshark/G-packet-index.md`, which points at packets in the saved capture.

Status: ☐ = not yet captured, ☑ = captured and checked.

| Spec item | What it proves | File(s) | Owner | ☐/☑ |
|---|---|---|---|---|
| A · IP inventory | IP, mask, gateway, interface, MAC of all 3 Macs | `A-lan/A1-{tathagat,thejas,garv}-netinfo.txt` | each | ☑ |
| A · Reachability | every pair pings, TTL 64, 0% loss | `A-lan/A2-{tathagat,thejas,garv}-ping.txt` | each | ☑ |
| A · Topology | diagram with roles | `../docs/topology.svg`, `../docs/ARCHITECTURE.md` §2 | Tathagat | ☑ |
| B · Config | IPs set, dnsmasq syntax OK | `B-dns/B1-tathagat-set-ips.txt` | Tathagat | ☑ |
| B · Server answers | dig on the DNS server | `B-dns/B2-tathagat-dig-on-server.txt` | Tathagat | ☑ |
| B · Across the LAN | dig @team-DNS from a client | `B-dns/B3-garv-dig-team-server.txt` | Garv Verma | ☑ |
| B · Two clients use team DNS | resolver set; `dig` shows `SERVER: <T>#53`; nslookup | `B-dns/B4-{thejas,garv}-client-resolver.txt`, `B4-*-dns-settings.png` | MS Thejas, Garv Verma | ☑ |
| B · Forwarding | non-project names still resolve | `B-dns/B5-garv-forwarding.txt` | Garv Verma | ☑ |
| B · Server-side proof | dnsmasq logged queries from both clients | `B-dns/B6-tathagat-query-log.txt` | Tathagat | ☑ |
| C · Backends listen on LAN | `*:3001`, `*:3002` | `C-backends/C1-{thejas,garv}-listening.txt` | MS Thejas, Garv Verma | ☑ |
| C · Endpoints + X-Backend | `/`, `/api/status` from the edge | `C-backends/C2-tathagat-direct-backends.txt` | Tathagat | ☑ |
| C/D · Backends only see the edge | `from=<T>` on every proxied request | `C-backends/C3-{thejas,garv}-backend-log.txt` | MS Thejas, Garv Verma | ☑ |
| D · nginx config | `nginx -t` OK | `D-loadbalancer/D1-tathagat-nginx-test.txt` | Tathagat | ☑ |
| D · Round-robin by name | A/B alternating | `D-loadbalancer/D2-garv-round-robin.txt` | Garv Verma | ☑ |
| D · Server-side LB proof | access log `upstream=` alternating | `D-loadbalancer/D3-tathagat-access-log.txt` | Tathagat | ☑ |
| E · Certificate | chain OK, SAN names only | `E-tls/E1-tathagat-certificate.txt` | Tathagat | ☑ |
| E · CA trusted on clients | system trust accepts cert for app.team67.test | `E-tls/E2-{thejas,garv}-system-trust.txt`, `E2-thejas-keychain.jpeg` | MS Thejas, Garv Verma | ☑ |
| E · HTTPS, no -k | `HTTP/2 200` by name | `E-tls/E3-{thejas,garv}-https.txt` | MS Thejas, Garv Verma | ☑ |
| E · Browser | padlock, certificate viewer | `E-tls/E4-thejas-browser-padlock.jpeg`, `E4-thejas-certificate-viewer.jpeg` | MS Thejas | ☑ |
| E · HTTP/1.1 + HTTP/2 | both versions via ALPN | `E-tls/E5-garv-http-versions.txt` | Garv Verma | ☑ |
| E · HTTP → HTTPS | `301` redirect | `E-tls/E6-garv-http-redirect.txt` | Garv Verma | ☑ |
| F · Cache headers | Cache-Control + ETag | `F-caching/F1-thejas-cache-headers.txt` | MS Thejas | ☑ |
| F · Conditional request | `304 Not Modified` | `F-caching/F2-thejas-conditional-304.txt` | MS Thejas | ☑ |
| F · Fresh hit | "(disk cache)" | `F-caching/F3-thejas-devtools-disk-cache.jpeg` | MS Thejas | ☑ |
| G · Full capture | DNS → TCP → TLS → encrypted HTTP | `G-wireshark/G-team67-full-flow.pcapng`, `G-team67-app-flow.pcapng` | Garv Verma | ☑ |
| G · Packet walk-through | packet numbers, ports, MACs | `G-wireshark/G-packet-index.md`, `G2`–`G8` screenshots (G0 setup screen optional) | Garv Verma | ☑ |
| G · Application view | handshake + headers from curl | `G-wireshark/G1-garv-curl-verbose.txt` | Garv Verma | ☑ |
| §6.3 Wrong DNS server | NXDOMAIN but IP reachable | `H-failures/H1-garv-wrong-dns-server.txt`, `H1-garv-restore.txt` | Garv Verma | ☑ |
| §6.3 Wrong record | resolves, TCP 443 fails | `H-failures/H2-tathagat-wrong-record.txt`, `H2-garv-wrong-record.txt` | Tathagat, Garv Verma | ☑ |
| §6.3 One backend down | only B serves; error log | `H-failures/H3-garv-one-backend-down.txt`, `H3-tathagat-nginx-error-log.txt` | MS Thejas, Garv Verma, Tathagat | ☑ |
| Recovery | A/B resumes | `H-failures/H3r-garv-recovery.txt` | MS Thejas, Garv Verma | ☑ |
| §6.3 Both backends down | TLS OK, `502` | `H-failures/H4-garv-both-backends-down.txt` | MS Thejas, Garv Verma | ☑ |
| §6.3 Wrong port | 443 open, 8443 refused | `H-failures/H5-garv-wrong-port.txt` | Garv Verma | ☑ |

## Screenshots (full instructions: docs/TEAM67-GUIDE.pdf section 5)

| # | File | Owner | ☐/☑ |
|---|---|---|---|
| S1 | `B-dns/B4-thejas-dns-settings.jpeg` | MS Thejas | ☑ |
| S2 | `B-dns/B4-garv-dns-settings.jpeg` | Garv Verma | ☑ |
| S3 | `B-dns/B6-tathagat-dnsmasq-live.jpeg` | Tathagat | ☑ |
| S4 | `D-loadbalancer/D2-garv-round-robin-terminal.jpeg` | Garv Verma | ☑ |
| S5 | `C-backends/C3-thejas-backend-terminal.jpeg` | MS Thejas | ☑ |
| S6 | `C-backends/C3-garv-backend-terminal.jpeg` | Garv Verma | ☑ |
| S7 | `E-tls/E4-thejas-browser-padlock.jpeg` | MS Thejas | ☑ |
| S8 | `E-tls/E4-thejas-certificate-viewer.jpeg` | MS Thejas | ☑ |
| S9 | `E-tls/E2-thejas-keychain.jpeg` | MS Thejas | ☑ |
| S10 | `E-tls/E2-garv-keychain.jpeg` | Garv Verma | ☑ |
| S11 | `F-caching/F2-thejas-304-terminal.jpeg` | MS Thejas | ☑ |
| S12 | `F-caching/F3-thejas-devtools-disk-cache.jpeg` | MS Thejas | ☑ |
| S13 | `G-wireshark/G0-garv-capture-ready.png` | Garv Verma | optional (not taken) |
| S14 | `G-wireshark/G2-filter-dns.jpeg` | Garv Verma | ☑ |
| S15 | `G-wireshark/G3-filter-tcp-syn.jpeg` | Garv Verma | ☑ |
| S16 | `G-wireshark/G4-filter-tls-handshake.jpeg` | Garv Verma | ☑ |
| S17 | `G-wireshark/G5-full-flow.jpeg` | Garv Verma | ☑ |
| S18 | `G-wireshark/G6-dns-packet-ports.jpeg` | Garv Verma | ☑ |
| S19 | `G-wireshark/G7-syn-packet-ports.jpeg` | Garv Verma | ☑ |
| S20 | `G-wireshark/G8-encrypted-app-data.jpeg` | Garv Verma | ☑ |
| S21 | `G-wireshark/G9-tls13-handshake.png` | Garv Verma | optional (not taken) |
| S22 | `H-failures/H1-garv-wrong-dns-terminal.jpeg` | Garv Verma | ☑ |
| S23 | `H-failures/H3-garv-only-b-terminal.jpeg` | Garv Verma | ☑ |
| S24 | `H-failures/H3-tathagat-error-log.png` | Tathagat | optional (not taken) |
| S25 | `H-failures/H4-garv-502-terminal.jpeg` | Garv Verma | ☑ |
