#!/bin/sh
set -eu

TEMPLATE="$1"
OUT="$2"

# 例：把模板里的 __NODE_URL__ / __UUID__ 替换
sed \
  -e "s|__NODE_URL__|${NODE_URL}|g" \
  -e "s|__UUID__|${UUID}|g" \
  "$TEMPLATE" > "$OUT"
