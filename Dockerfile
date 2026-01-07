# syntax=docker/dockerfile:1

FROM golang:1.25.1-alpine AS builder
RUN apk add --no-cache git build-base
WORKDIR /src

ARG SING_BOX_REF=v1.12.14
RUN git clone https://github.com/SagerNet/sing-box.git .
RUN git checkout ${SING_BOX_REF}

RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/sing-box ./cmd/sing-box

FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata && update-ca-certificates

WORKDIR /app
COPY --from=builder /out/sing-box /usr/local/bin/sing-box

# 放入配置模板（不含敏感信息）
COPY config/config.template.json /app/config.template.json

# entrypoint 渲染逻辑
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 非 root（可选）
RUN adduser -D -H -s /sbin/nologin appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8181
ENTRYPOINT ["/entrypoint.sh"]
