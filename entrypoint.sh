#!/bin/sh
set -eu

TEMPLATE="/app/config.template.json"
CONFIG="/app/config.json"

# 如果用户运行时挂载了完整 config.json，就直接用
if [ -f "$CONFIG" ]; then
  echo "INFO: Found /app/config.json (mounted). Using it directly."
  exec sing-box run -c "$CONFIG"
fi

if [ ! -f "$TEMPLATE" ]; then
  echo "ERROR: /app/config.json not found and /app/config.template.json not found."
  exit 1
fi

# 如果未提供 PASSWORD，则生成一个随机密码，并打印出来
if [ "${PASSWORD:-}" = "" ]; then
  PASSWORD="$(head -c 96 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 24 || true)"
  if [ "${PASSWORD:-}" = "" ]; then
    echo "ERROR: failed to generate PASSWORD; please set env PASSWORD."
    exit 1
  fi
  echo "INFO: Generated random PASSWORD: ${PASSWORD}"
else
  echo "INFO: Using PASSWORD from env (not generated)."
fi

# 渲染模板：把 "password": "*" 替换成生成/注入的 PASSWORD
# 建议 PASSWORD 仅使用字母数字（本脚本生成也是如此），避免 JSON 转义问题
sed "s/\"password\"[[:space:]]*:[[:space:]]*\"\\*\"/\"password\": \"${PASSWORD}\"/g" \
  "$TEMPLATE" > "$CONFIG"

exec sing-box run -c "$CONFIG"
