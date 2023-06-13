# 構築手順

## gcloud コマンドセットアップ

```sh
PROJECT_ID=kyo2bay-gcp-run-sql
gcloud config configurations create ${PROJECT_ID}
gcloud config set project ${PROJECT_ID}
gcloud auth login
```

## Terraform state 管理用バックエンド Cloud Storage バケット作成

```sh
PROJECT_ID=$(gcloud config get-value project)
gsutil mb -l asia-northeast1 -b on gs://${PROJECT_ID}-tf-state
gsutil versioning set on gs://${PROJECT_ID}-tf-state
gcloud auth application-default login
```

## サンプルアプリケーションのコンテナイメージビルド

https://cloud.google.com/sql/docs/postgres/connect-instance-cloud-run?hl=ja#configure_a_sample_app

## Terraform 実行

### Cloud SQL 関連以外を構築

```sh
cd terraform
terraform init -reconfigure
terraform apply
```

### Cloud SQL 関連を構築

```sh
# Cloud SQL 関連コードのコメントアウトを解除
terraform apply
```
