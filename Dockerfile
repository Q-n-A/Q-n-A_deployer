FROM node:16.14.0 AS front-builder
WORKDIR /temp

RUN apt-get update && apt-get install jq unzip -y --no-install-recommends

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN URI=$(wget -O - -q https://api.github.com/repos/protocolbuffers/protobuf/releases | \
  jq -r '.[0].assets[] | select(.name | test("linux-x86_64.zip")) | .browser_download_url') && \
  wget --progress=dot:giga "$URI" -O "protobuf.zip" && \
  unzip -o protobuf.zip -d protobuf && \
  chmod -R 755 protobuf/*
ENV PATH $PATH:/temp/protobuf/bin

RUN git clone https://github.com/Q-n-A/Q-n-A_UI
WORKDIR /temp/Q-n-A_UI
RUN npm ci --unsafe-perm && \
  npm run gen && \
  npm run build

FROM golang:1.17.7 AS back-builder
WORKDIR /temp

RUN apt-get update && apt-get install jq unzip -y --no-install-recommends

COPY --from=front-builder /temp/protobuf /temp/protobuf/
ENV PATH $PATH:/temp/protobuf/bin

RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
  go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

RUN git clone https://github.com/Q-n-A/Q-n-A
WORKDIR /temp/Q-n-A
RUN go mod download && \
  make grpc-go && \
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /Q-n-A -ldflags '-s -w'

FROM caddy:2.4.6-alpine AS caddy

FROM envoyproxy/envoy-alpine:v1.21.1 AS runner
RUN apk add --no-cache  bash
EXPOSE 8080

COPY --from=front-builder /temp/Q-n-A_UI/dist /usr/share/caddy/
COPY --from=back-builder /Q-n-A /
COPY --from=caddy /usr/bin/caddy /usr/bin/
COPY ./settings/Caddyfile /etc/caddy/
COPY ./settings/envoy.yaml /etc/envoy/
COPY ./settings/entrypoint.sh /

HEALTHCHECK --interval=60s --timeout=3s --retries=5 CMD ./Q-n-A healthcheck || exit 1
ENTRYPOINT ["sh", "/entrypoint.sh"]
