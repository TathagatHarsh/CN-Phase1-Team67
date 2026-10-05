# Demo sequence and viva preparation

## Final demo sequence (spec §8 order; Phase 1 review = steps 1–8 + viva)

| # | Show | Presenter | Machine | What the evaluator sees |
|---|---|---|---|---|
| 1 | Topology, roles, IP/service table | Tathagat (each member states their own role) | slides / `ARCHITECTURE.md` | 3 Macs, 4 spec roles, ports, cloud equivalents |
| 2 | All Macs on the LAN | All | each Mac | `ipconfig getifaddr en0`, `ping` the other two |
| 3 | Resolve the private name | Garv Verma runs, Tathagat explains dnsmasq | Node 3 + Node 1 | `dig app.team67.test` → Node 1 IP, `SERVER: <T>#53`; the query appears live in the dnsmasq tab |
| 4 | HTTPS by name, no warnings | MS Thejas (browser), Garv Verma (curl) | Node 2, Node 3 | padlock, certificate chain to Team67 Local Root CA, `HTTP/2 200`, no `-k`, no IP in the URL |
| 5 | Load balancing | Tathagat (upstream config), Garv Verma (loop) | Node 1, Node 3 | `X-Backend: A/B` alternating; backend logs show `from=<edge IP>` |
| 6 | Wireshark: DNS, TCP, TLS | Garv Verma | Node 3 | saved pcap: DNS query/answer, SYN/SYN-ACK/ACK, TLS handshake, encrypted data, ports |
| 7 | Headers + caching | MS Thejas | Node 2 | `curl -I` Cache-Control/ETag, `304`, DevTools "(disk cache)" |
| 8 | One backend fails, service continues, recovers | MS Thejas stops A, Garv Verma shows B only, then A returns | Node 2, Node 3 | only `B`, nginx error log, then A/B again |
| 8b | Other failures if asked | Garv Verma / Tathagat | — | wrong DNS server, wrong record, both down = 502, wrong port |
| 9–10 | Phase 2 (backup DNS, TTL, cutover; injected fault) | — | — | Phase 2 review |
| 11 | Individual viva | All | — | every member answers about any part |

Before the demo: `RUNBOOK.md` step 1 IP check; the one-line health check from Garv Verma:
`for i in 1 2 3 4; do curl -si https://app.team67.test/api/status | grep -i x-backend; done` (A/B alternating = DNS, TCP, TLS, nginx and both backends are up).

## Question bank (every member must be able to answer all of these)

**Architecture**
1. *Why does one Mac run both DNS and nginx?* We are three people; the spec lets 2–3 member teams combine roles. Both need admin rights; the clients must be other Macs so traffic crosses the LAN.
2. *What is the single point of failure?* Node 1 (DNS + edge). Fix: backup DNS on another Mac, standby nginx and DNS cutover (Phase 2).
3. *Why doesn't the client need the backend IPs?* It only knows the name; DNS gives the edge's IP, and only nginx's upstream lists the backends. Backends can change without touching clients.
4. *Cloud equivalents?* dnsmasq = Route 53 private hosted zone; nginx = ALB / CDN edge; backends = instances in a target group; max_fails = health checks; our CA = a private CA.

**DNS**
5. *DNS resolution vs the connection?* DNS only turns a name into an IP (UDP 53). Then a separate TCP connection to that IP on 443 carries TLS and HTTP. DNS is a directory, not a connection.
6. *What does `local=/team67.test/` do?* dnsmasq is authoritative for the zone: answers our records, returns NXDOMAIN for other team67.test names, never forwards them upstream.
7. *Why `.test`, not `.local`?* `.test` is reserved for testing (RFC 6761); `.local` belongs to mDNS/Bonjour on macOS.
8. *What is the TTL for?* How long a resolver may cache the answer (60 s). Short TTL = faster changes, more queries.
9. *Why UDP for DNS?* One small question and answer, no handshake needed; TCP is used for large answers or zone transfers.
10. *Wrong DNS server demo shows what?* Name lookup fails but `ping` and `--resolve` to the IP work: DNS and IP connectivity are independent.

**TCP / ports**
11. *Three-way handshake?* SYN (client ISN) → SYN-ACK (server ISN, ack = client ISN+1) → ACK. Only then data.
12. *Socket pair in our capture?* (client IP, ephemeral port) ↔ (Node 1 IP, 443); DNS: (client IP, ephemeral) ↔ (Node 1 IP, 53/udp).
13. *Sequence and acknowledgement numbers?* Seq numbers count bytes sent; ACK = next byte expected. Lost segments are detected by missing ACKs/duplicate ACKs and retransmitted.
14. *Wrong port demo?* Same host answers on 443 but refuses 8443: the IP selects the machine, the port selects the service.
15. *Why bind backends to 0.0.0.0?* 127.0.0.1 accepts only local connections, so Node 1 could not reach them.

**TLS / HTTPS**
16. *TLS 1.2 handshake?* ClientHello (versions, ciphers, SNI, ALPN) → ServerHello + Certificate + ServerKeyExchange + ServerHelloDone → ClientKeyExchange + ChangeCipherSpec + Finished → server ChangeCipherSpec + Finished.
17. *Why capture with `--tls-max 1.2`?* TLS 1.3 encrypts the Certificate message, so it would not be visible in Wireshark.
18. *How does the client trust our certificate?* The cert is signed by Team67 Local Root CA, which is in the client's System keychain as trusted; the name matches the SAN; dates are valid.
19. *Why a CA instead of one self-signed cert?* Clients trust the CA once; server certs can be reissued without touching clients.
20. *What is TLS termination?* nginx decrypts at the edge; nginx→backend is plain HTTP inside our LAN.
21. *What are SNI and ALPN?* SNI tells the server which hostname we want (before encryption); ALPN agrees on h2 or http/1.1 inside the handshake.
22. *Why is the payload unreadable in Wireshark?* After the handshake all HTTP is TLS Application Data encrypted with session keys only the client and nginx have.
23. *Why never `-k`?* It disables certificate checks, so nothing about trust would be proven.

**HTTP / REST / caching**
24. *HTTP/1.1 vs HTTP/2?* HTTP/2 is binary and multiplexes many streams on one connection with header compression; we show both with `--http1.1`/`--http2`. HTTP/3 runs over QUIC (UDP), explanation-only.
25. *Fresh hit vs conditional request vs full request?* Within max-age: no request at all. After: `If-None-Match` → `304`, no body. No copy: `200` with body.
26. *Why does the 304 work behind a load balancer?* Both backends serve identical content, so the ETag is identical whichever backend answers.
27. *Why is `/api/status` `no-store`?* So every request reaches a backend and the A/B alternation stays visible.
28. *What is REST here?* Resources at URLs, standard GET, stateless JSON responses.

**Load balancing / failures**
29. *Round-robin?* Requests go A, B, A, B. Alternative: `least_conn` sends to the backend with the fewest active connections.
30. *What happens when Backend A stops?* Connection refused → nginx retries on B (`proxy_next_upstream`) and marks A failed for 10 s (`max_fails=1 fail_timeout=10s`) → all traffic to B. After restart, A rejoins.
31. *Both backends down → 502, why?* DNS, TCP and TLS to the edge still work; nginx has no upstream to forward to, so it returns 502 Bad Gateway. Shows where the edge ends and the backend begins.
32. *DNS record points to the wrong IP?* Resolution succeeds, but the client connects to a host without nginx → TCP refused.
33. *How do you diagnose an unknown fault?* Layer by layer: dig → ping → nc to 443 → curl -v (TLS) → HTTP status/headers (see RUNBOOK).

**Layers**
34. *Map our protocols to OSI layers.* DNS/HTTP = 7, TLS = 5–6, TCP/UDP = 4, IP = 3, Ethernet/Wi-Fi + ARP = 2. (Table in ARCHITECTURE §4.)
35. *Why is the destination MAC Node 1's, not the router's?* Node 1 is on the same subnet, so the frame goes straight to it; the gateway is only used for other networks.
36. *Email protocols (explanation only)?* SMTP sends mail between servers (25/587), IMAP (143/993) and POP3 (110/995) fetch it; like HTTPS, they are application protocols over TCP, usually wrapped in TLS.
