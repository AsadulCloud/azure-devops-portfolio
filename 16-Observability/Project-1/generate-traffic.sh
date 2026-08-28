#!/usr/bin/env bash
# Generate traffic against service-a so Grafana panels show live data.
# Usage: ./generate-traffic.sh [BASE_URL]
# Example: ./generate-traffic.sh http://demo.158.158.93.96.nip.io/service-a

set -euo pipefail

BASE_URL="${1:-http://demo.158.158.93.96.nip.io/service-a}"

echo "Sending traffic to: $BASE_URL"
echo "(healthy + occasional /serverError and /example)"

for i in $(seq 1 100); do
  curl -s -o /dev/null "$BASE_URL/healthy" || true
  if [ $((i % 8)) -eq 0 ]; then
    curl -s -o /dev/null "$BASE_URL/serverError" || true
  fi
  if [ $((i % 15)) -eq 0 ]; then
    curl -s -o /dev/null "$BASE_URL/example" || true
  fi
  sleep 0.3
done

echo "Done — 100 requests sent. Check Request Rate / Error Rate panels in Grafana."
