#!/bin/bash
# Record one command and its real, unedited output into an evidence file (appends).
# Usage: scripts/rec.sh <evidence-file> '<command>'
#   e.g. scripts/rec.sh B-dns/B3-garv-dig.txt 'dig app.team67.test'
# Relative file names go under ~/team67-evidence/ (AirDrop that folder to Tathagat at the end).
# Each entry starts with: time | user@host | this Mac's IP and interface | the exact command.
[ $# -eq 2 ] || { echo "usage: $0 <evidence-file> '<command>'"; exit 1; }
out=$1; cmd=$2
case $out in /*) ;; *) out="$HOME/team67-evidence/$out" ;; esac
mkdir -p "$(dirname "$out")"
iface=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
{
  echo "### $(date '+%Y-%m-%d %H:%M:%S %Z') | $(whoami)@$(hostname -s) | ${iface:-?} $(ipconfig getifaddr "${iface:-en0}" 2>/dev/null)"
  echo "\$ $cmd"
  bash -c "$cmd" 2>&1
  echo "[exit=$?]"
  echo
} | tee -a "$out"
