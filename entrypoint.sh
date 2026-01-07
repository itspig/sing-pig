#!/bin/sh
set -eu

TEMPLATE="/app/config.template.json"
CONFIG="/app/config.json"

# 如果用户运行时挂载了完整 config.json，就直接用
if [ -f "$CONFIG" ]; then
  exec sing-box run -c "$CONFIG"
fi

# 否则必须有模板
if [ ! -f "$TEMPLATE" ]; then
  echo "ERROR: $CONFIG not found and $TEMPLATE not found."
  exit 1
fi

# password 来源优先级：
# 1) 环境变量 PASSWORD（你传参生成/注入）
# 2) 未提供则自动生成一个随机 password（避免起不来）
if [ "${PASSWORD:-}" = "" ]; then
  # 生成 24 字符随机串（不依赖 openssl）
  PASSWORD="$(head -c 64 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 24 || true)"
  if [ "${PASSWORD:-}" = "" ]; then
    echo "ERROR: failed to generate PASSWORD; please set env PASSWORD."
    exit 1
  fi
  echo "INFO: PASSWORD not provided; generated one (not printed)."
fi

# 用 sed 把模板中的 "password": "*" 替换成你的 PASSWORD
# 注意：如果你的模板里有多个 password="*"，会全部替换（符合大多数需求）
# 为避免特殊字符破坏 JSON，这里建议 PASSWORD 仅用 [A-Za-z0-9]（上面自动生成也是这个集合）
sed "s/\"password\"[[:space:]]*:[[:space:]]*\"\\*\"/\"password\": \"${PASSWORD}\"/g" \
  "$TEMPLATE" > "$CONFIG"

exec sing-box run -c "$CONFIG"
