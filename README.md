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

## Terraform 実行

```sh
cd terraform
terraform init -reconfigure
terraform apply
# output に表示される ip アドレスにアクセスして動作確認 (apply 後数分後)
```

## サンプルアプリケーションのコンテナイメージビルド

https://cloud.google.com/sql/docs/postgres/connect-instance-cloud-run?hl=ja#configure_a_sample_app

## Cloud SQL にクエリを実行する

```sh
# Cloud SQL インスタンスの コンソール画面から Cloud Shell を起動
gcloud sql connect gcp-run-sql-instance --user=demo_user --database=demo_db --quiet
SELECT * FROM votes;
```
