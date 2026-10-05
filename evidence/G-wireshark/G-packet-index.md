# G · Packet index

Captured on Garv Verma's Mac (10.7.1.77, MAC a2:dc:7b:8f:5e:71), interface Wi-Fi (en0), capture filter `host 10.7.27.239`, 2026-10-05.
Request: `curl -v --tls-max 1.2 https://app.team67.test/api/status` (application view: `G1-garv-curl-verbose.txt`).
Files: `G-team67-full-flow.pcapng` (whole capture, 34 packets), `G-team67-app-flow.pcapng` (display filter
`dns.qry.name == "app.team67.test" || tcp.port == 443`, 32 packets). Packet numbers below are from the full capture.

| Packet no. | Layer | Source → Destination | What it shows |
|---|---|---|---|
| 3 | DNS / UDP | 10.7.1.77:65190 → 10.7.27.239:53 | Standard query 0x4c60, `A app.team67.test` |
| 4 | DNS / UDP | 10.7.27.239:53 → 10.7.1.77:65190 | Standard query response 0x4c60, `A 10.7.27.239`, TTL 60 s (dnsmasq local-ttl=60) |
| 5 | TCP | 10.7.1.77:57006 → 10.7.27.239:443 | SYN, Seq=0, Win=65535, MSS=1460, WS=64, SACK_PERM (ECE, CWR set: ECN offered) |
| 6 | TCP | 10.7.27.239:443 → 10.7.1.77:57006 | SYN, ACK, Seq=0 Ack=1, MSS=1460 |
| 7 | TCP | 10.7.1.77:57006 → 10.7.27.239:443 | ACK, Seq=1 Ack=1: three-way handshake complete |
| 8 | TLS 1.2 | Garv Verma → Node 1 | Client Hello, SNI = app.team67.test (298 bytes) |
| 11 | TLS 1.2 | Node 1 → Garv Verma | Server Hello, Certificate, Server Key Exchange, Server Hello Done (1437 bytes) |
| 13 | TLS 1.2 | Garv Verma → Node 1 | Client Key Exchange, Change Cipher Spec, Encrypted Handshake Message (Finished) |
| 15 | TLS 1.2 | Node 1 → Garv Verma | Change Cipher Spec, Encrypted Handshake Message (Finished) |
| 16, 18, 19, 21, 25 | TLS Application Data | both | HTTP/2 request and response, encrypted |
| 10, 12, 14, 17, 20, 22 | TCP | both | ACKs: Seq/Ack numbers advance by the bytes received (e.g. pkt 10 Ack=233 after the 232-byte Client Hello) |
| 23, 24 | TCP | both | Keep-Alive and Keep-Alive ACK |
| 27 | TLS | Garv Verma → Node 1 | Encrypted Alert (TLS close_notify) |
| 28 | TCP | Garv Verma → Node 1 | FIN, ACK: client starts closing |
| 29, 30, 34 | TCP | both | Spurious retransmission / retransmissions of FIN: segments re-sent after Wi-Fi delay |
| 33 | TCP | Node 1 → Garv Verma | RST, ACK: server resets the leftover half of the connection |

Link layer (packet 8 details): Ethernet II, Src a2:dc:7b:8f:5e:71 (Garv Verma), Dst 7e:54:32:73:01:15 (Tathagat, Node 1,
see `A-lan/A1-tathagat-netinfo.txt`), not the gateway: same subnet, direct delivery.
Ports: client ephemeral ports 65190 (DNS, packet 3) and 57006 (HTTPS); server well-known ports 53/UDP and 443/TCP.
TCP reliability seen in this capture: retransmissions in packets 29, 30 and 34 on the busy college Wi-Fi.
