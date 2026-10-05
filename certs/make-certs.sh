#!/bin/bash
# Team 67: root CA + server certificate for app/api.team67.test. Run on Node 1 (Tathagat).
# Output: rootCA.pem -> give to Thejas and Garv | team67.crt -> nginx
#         rootCA.key, team67.key -> NEVER share (git-ignored)
# No IPs inside, so the same certificate works on the single-Mac run and on Monday's LAN.
set -euo pipefail
cd "$(dirname "$0")"
OPENSSL="$(brew --prefix openssl@3)/bin/openssl"   # /usr/bin/openssl is LibreSSL
"$OPENSSL" version

# 1. Root CA (self-signed, 825 days)
"$OPENSSL" req -x509 -new -nodes -newkey rsa:2048 -keyout rootCA.key -out rootCA.pem \
  -days 825 -config ca.cnf -extensions v3_ca

# 2. Server key + CSR, signed by our CA (397 days, within Apple's TLS limit)
"$OPENSSL" req -new -nodes -newkey rsa:2048 -keyout team67.key -out team67.csr -config leaf.cnf
"$OPENSSL" x509 -req -in team67.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial \
  -out team67.crt -days 397 -sha256 -extfile leaf.cnf -extensions v3_leaf
chmod 600 rootCA.key team67.key

# 3. Verify the chain and show what clients will check
"$OPENSSL" verify -CAfile rootCA.pem team67.crt
"$OPENSSL" x509 -in team67.crt -noout -subject -issuer -dates -ext subjectAltName
