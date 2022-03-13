# Q-n-A_deployer

[![CI Pipeline](https://github.com/Q-n-A/Q-n-A_deployer/actions/workflows/CI.yml/badge.svg)](https://github.com/Q-n-A/Q-n-A_deployer/actions/workflows/CI.yml)
[![CD Pipeline](https://github.com/Q-n-A/Q-n-A_deployer/actions/workflows/CD.yml/badge.svg)](https://github.com/Q-n-A/Q-n-A_deployer/actions/workflows/CD.yml)

Q'n'A Deploy Scripts on Showcase

## 各ファイルの説明

- `Dockerfile`: ビルド用Dockerfile
- `docker-compose.yml`: テスト用Docker Compose設定ファイル
- `settings/*`: envoy、caddy、エントリーポイント設定ファイル
- `showcase.yml`: Showcase用設定ファイル

## 手元でのテスト

```sh
docker-compose up -d
```

`localhost:9000`でクライアント(`/`)、REST APIサーバー(`/api/*`)、gRPCサーバー(`/grpc`)を確認できます。

※ `/grpc`は、gRPCurlが使えないので、手元のクライアント実装を使用して下さい。
