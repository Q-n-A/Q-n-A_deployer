#!/bin/sh

caddy start --config /etc/caddy/Caddyfile --adapter caddyfile
envoy -c /etc/envoy/envoy.yaml >/dev/null 2>&1 &
/Q-n-A config
/Q-n-A serve
