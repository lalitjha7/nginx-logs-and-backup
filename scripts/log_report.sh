#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-/var/log/nginx/access.log}"
OUT_DIR="${2:-$(dirname "$0")/../reports}"
OUT_FILE="${OUT_DIR}/report_$(date +%F).txt"

mkdir -p "$OUT_DIR"
[[ -r "$LOG_FILE" ]] || { echo "ERROR: cannot read $LOG_FILE" >&2; exit 1; }

# Keep only well-formed lines: field 9 must be a 3-digit status code
VALID="$(awk '$9 ~ /^[0-9][0-9][0-9]$/' "$LOG_FILE")"
if [[ -z "$VALID" ]]; then
  TOTAL=0
else
  TOTAL=$(printf '%s\n' "$VALID" | wc -l)
fi
ALL=$(wc -l < "$LOG_FILE")
MALFORMED=$(( ALL - TOTAL ))

{
  echo "===== Nginx Traffic Report ====="
  echo "Generated       : $(date '+%F %T')"
  echo "Log file        : $LOG_FILE"
  echo
  echo "Total requests  : $TOTAL"
  echo "Malformed lines : $MALFORMED"
  echo

  if (( TOTAL == 0 )); then
    echo "No valid requests found."
  else
    echo "--- Top 10 IP addresses ---"
    printf '%s\n' "$VALID" | awk '{print $1}' | sort | uniq -c | sort -rn | head -10
    echo
    echo "--- Top 10 requested URLs ---"
    printf '%s\n' "$VALID" | awk '{print $7}' | sort | uniq -c | sort -rn | head -10
    echo
    echo "--- Response code classes ---"
    printf '%s\n' "$VALID" | awk '
      $9 ~ /^2/ {a++} $9 ~ /^4/ {b++} $9 ~ /^5/ {c++}
      END {printf "2xx: %d\n4xx: %d\n5xx: %d\n", a, b, c}'
    echo
    echo "--- Requests per hour ---"
    printf '%s\n' "$VALID" | awk '{print $4}' | cut -d: -f1,2 | tr -d '[' \
      | sort | uniq -c | awk '{printf "%s:00  %d\n", $2, $1}'
  fi
} > "$OUT_FILE"

echo "Report written to $OUT_FILE"
