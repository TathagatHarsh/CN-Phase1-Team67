#!/bin/bash
# Put the three real Wi-Fi IPs into the DNS and nginx configs. Run on Tathagat's Mac, from anywhere.
# Usage: scripts/set-ips.sh <TATHAGAT_IP> <THEJAS_IP> <GARV_IP>
# Safe to re-run whenever an IP changes (DHCP): lines are rewritten by pattern, not by old value.
set -euo pipefail
cd "$(dirname "$0")/.."
[ $# -eq 3 ] || { echo "usage: $0 <TATHAGAT_IP> <THEJAS_IP> <GARV_IP>"; exit 1; }
for ip in "$@"; do
  [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || { echo "not an IPv4 address: $ip"; exit 1; }
done
T=$1 J=$2 G=$3

sed -i '' -E \
  -e "s/^listen-address=[0-9.]+/listen-address=$T/" \
  -e "s/^(host-record=(app|api)\.team67\.test,)[0-9.]+/\1$T/" dns/dnsmasq.conf
sed -i '' -E \
  -e "s/listen [0-9.]+:(80|443)/listen $T:\1/" \
  -e "s/server [0-9.]+:3001/server $J:3001/" \
  -e "s/server [0-9.]+:3002/server $G:3002/" nginx/team67.conf

echo "--- dns/dnsmasq.conf";  grep -nE '^(listen-address|host-record)' dns/dnsmasq.conf
echo "--- nginx/team67.conf"; grep -nE 'listen [0-9]|server [0-9]' nginx/team67.conf
/opt/homebrew/sbin/dnsmasq --test -C dns/dnsmasq.conf
echo "Next: sudo nginx -t -p \"\$PWD/\" -c nginx/team67.conf   then restart dnsmasq and reload nginx"
