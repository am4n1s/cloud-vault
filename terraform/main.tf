terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    minio = {
      source  = "aminueza/minio"
      version = "~> 2.0"
    }
  }
}

# MinIO provider для S3 bucket
provider "minio" {
  minio_server   = "localhost:9000"
  minio_user     = "minioadmin"
  minio_password = "minioadmin"
  minio_ssl      = false
}

# AWS provider для DynamoDB Local
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "minioadmin"
  secret_key                  = "minioadmin"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    dynamodb = "http://localhost:8000"
  }
}

# S3 Bucket в MinIO через minio provider
resource "minio_s3_bucket" "cloud_vault_bucket" {
  bucket = "cloud-vault-bucket"
  acl    = "private"
}

# DynamoDB таблица
resource "aws_dynamodb_table" "users" {
  name         = "Users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "username"

  attribute {
    name = "username"
    type = "S"
  }

  tags = {
    Name        = "cloud-vault-users"
    Environment = "local"
  }
}
