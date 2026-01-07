# syntax=docker/dockerfile:1

FROM golang:1.22-alpine AS builder
RUN apk add --no-cache git build-base
WORKDIR /src

# 方式A：直接从官方仓库拉源码编译
# 你也可以用 release 版本号 checkout
ARG SING_BOX_REF=v1.12.14
RUN git clone https://github.com/SagerNet/sing-box.git .
RUN git checkout ${SING_BOX_REF}

# 编译：最常见用法是构建 sing-box 主程序
# 注意：不同版本 build 方式可能略有变化；若失败，改为 `go build ./cmd/sing-box`
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/sing-box ./cmd/sing-box

FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata && update-ca-certificates
WORKDIR /app

# 复制二进制
COPY --from=builder /out/sing-box /usr/local/bin/sing-box

# 复制配置（你也可以在 workflow 里生成 config.json 再 COPY）
COPY config/config.json /app/config.json

# 以非 root 运行（可选）
RUN adduser -D -H -s /sbin/nologin appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 1080  # 按你的入站端口改
ENTRYPOINT ["sing-box", "run", "-c", "/app/config.json"]
