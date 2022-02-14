FROM logica0419/protoc-node:16.14.0 AS front-builder
WORKDIR /build
RUN apt-get update && apt-get install git

RUN git clone https://github.com/Q-n-A/Q-n-A_UI
WORKDIR /build/Q-n-A_UI
RUN npm ci --unsafe-perm
RUN npm run gen
RUN npm run build

FROM logica0419/protoc-go:1.17.7 AS back-builder
WORKDIR /build
RUN apt-get update && apt-get install git

RUN git clone https://github.com/Q-n-A/Q-n-A
WORKDIR /build/Q-n-A
RUN make grpc-go
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /Q-n-A -ldflags '-s -w'

FROM caddy:2.4.6-alpine AS caddy

FROM envoyproxy/envoy-alpine:v1.21.0 AS runner
RUN apk update && apk upgrade && apk add bash
EXPOSE 8080

COPY --from=front-builder /build/Q-n-A_UI/dist /usr/share/caddy/
COPY --from=back-builder /Q-n-A /
COPY --from=caddy /usr/bin/caddy /usr/bin/
COPY ./settings/Caddyfile /etc/caddy/
COPY ./settings/envoy.yaml /etc/envoy/
COPY ./settings/entrypoint.sh /

HEALTHCHECK --interval=60s --timeout=3s --retries=5 CMD ./Q-n-A healthcheck || exit 1
ENTRYPOINT sh /entrypoint.sh
