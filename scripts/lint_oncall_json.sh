#!/usr/bin/env bash
set -euo pipefail

FILE="$1"

echo "Linting $FILE"

# ---------- 1. Valid JSON ----------
jq empty "$FILE" >/dev/null || {
  echo "Invalid JSON"
  exit 1
}

# ---------- 2. `on` must exist and be array ----------
jq -e '.on | type == "array"' "$FILE" >/dev/null || {
  echo "'on' must be an array"
  exit 1
}

# ---------- 3. Validate each entry ----------
jq -e '
  .on[] |
  has("se") and
  (.se | type == "string" and length > 0) and
  has("sch") and
  (.sch | type == "array" and length > 0) and
  (.sch[] | type == "string" and length > 0)
' "$FILE" >/dev/null || {
  echo " Each item must have valid se (string) and sch (array of strings)"
  exit 1
}

# ---------- 4. No commas in sch values ----------
jq -e '
  .on[].sch[] | contains(",") | not
' "$FILE" >/dev/null || {
  echo " sch values must NOT contain commas"
  exit 1
}

# ---------- 5. No duplicate se ----------
DUP_SE=$(jq -r '.on[].se' "$FILE" | sort | uniq -d)
if [[ -n "$DUP_SE" ]]; then
  echo " Duplicate se values found:"
  echo "$DUP_SE"
  exit 1
fi

echo " JSON lint passed"
