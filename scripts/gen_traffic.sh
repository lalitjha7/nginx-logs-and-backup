#!/usr/bin/env bash
set -euo pipefail

valid=("/" "/index.html")
invalid=("/missing" "/admin" "/wp-login.php" "/nope.html" "/api/v1/users")
own_ip="$(hostname -I | awk '{print $1}')"
hosts=("127.0.0.1" "localhost" "$own_ip")

for _ in $(seq 1 200); do
  host="${hosts[RANDOM % ${#hosts[@]}]}"
  if (( RANDOM % 4 == 0 )); then
    path="${invalid[RANDOM % ${#invalid[@]}]}"
  else
    path="${valid[RANDOM % ${#valid[@]}]}"
  fi
  curl -s -o /dev/null "http://${host}${path}"
done
echo "Traffic generated."
