# Q-n-A_deployer

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
