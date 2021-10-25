FROM node:16.12.0-alpine AS front-builder
WORKDIR /build
RUN apk add git

RUN git clone https://github.com/Q-n-A-dev-team/Q-n-A_UI
WORKDIR /build/Q-n-A_UI
RUN npm ci --unsafe-perm
RUN npm run build

FROM golang:1.17.2-alpine AS back-builder
WORKDIR /build
RUN apk add git

RUN git clone https://github.com/Q-n-A-dev-team/Q-n-A
WORKDIR /build/Q-n-A
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /Q-n-A -ldflags '-s -w'

FROM caddy:2.4.5-alpine AS runner
RUN apk update && apk upgrade && apk add bash
EXPOSE 80

COPY --from=front-builder /build/Q-n-A_UI/dist /usr/share/caddy
COPY --from=back-builder /Q-n-A /
COPY ./Caddyfile /etc/caddy/Caddyfile

HEALTHCHECK CMD ./Q-n-A healthcheck || exit 1
ENTRYPOINT caddy start --config /etc/caddy/Caddyfile --adapter caddyfile && /Q-n-A
