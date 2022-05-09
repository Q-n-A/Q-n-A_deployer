FROM golang:1.18.0 AS back-builder
ARG TARGETARCH
WORKDIR /temp

RUN apt-get update && apt-get install jq unzip -y --no-install-recommends

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN if [ "$TARGETARCH" = "amd64" ]; then PROTOC_ARCH="x86_64"; elif [[ "$TARGETARCH" = "arm"* ]]; then PROTOC_ARCH="aarch_64"; else exit 1; fi && \
  URI=$(wget -O - -q https://api.github.com/repos/protocolbuffers/protobuf/releases | \
  jq -r --arg arch "linux-$PROTOC_ARCH" '.[0].assets[] | select(.name | test($arch)) | .browser_download_url') && \
  wget --progress=dot:giga "$URI" -O "protobuf.zip" && \
  unzip -o protobuf.zip -d protobuf && \
  chmod -R 755 protobuf/*
ENV PATH $PATH:/temp/protobuf/bin

RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
  go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

RUN git clone https://github.com/Q-n-A/Q-n-A
WORKDIR /temp/Q-n-A
RUN go mod download && \
  make grpc-go && \
  CGO_ENABLED=0 GOOS=linux GOARCH="$TARGETARCH" go build -o /Q-n-A -ldflags '-s -w'

FROM node:16.14.2 AS front-builder
WORKDIR /temp

COPY --from=back-builder /temp/protobuf /temp/protobuf/
ENV PATH $PATH:/temp/protobuf/bin

RUN git clone https://github.com/Q-n-A/Q-n-A_UI
WORKDIR /temp/Q-n-A_UI
RUN npm ci --unsafe-perm && \
  npm run gen && \
  npm run build

FROM caddy:2.5.1-alpine AS caddy

FROM envoyproxy/envoy-alpine:v1.21.1 AS runner
RUN apk add --no-cache  bash

COPY --from=front-builder /temp/Q-n-A_UI/dist /usr/share/caddy/
COPY --from=back-builder /Q-n-A /
COPY --from=caddy /usr/bin/caddy /usr/bin/
COPY ./settings/Caddyfile /etc/caddy/
COPY ./settings/envoy.yaml /etc/envoy/
COPY ./settings/entrypoint.sh /

EXPOSE 8080

HEALTHCHECK --interval=60s --timeout=3s --retries=5 CMD ./Q-n-A healthcheck || exit 1
ENTRYPOINT ["sh", "/entrypoint.sh"]
