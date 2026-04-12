terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State remoto no S3. O bucket emcq-terraform-state precisa existir antes
  # de rodar terraform init (criar manualmente via AWS CLI ou Console).
  backend "s3" {
    bucket = "emcq-terraform-state"
    key    = "emcq_indicadores_economicos/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# ──────────────────────────────────────────────
# S3 Buckets (um por camada por ambiente)
# ──────────────────────────────────────────────

# Cria os 6 buckets iterando sobre o mapa definido em locals.tf.
# Cada entrada do mapa é uma combinação ambiente-camada (ex: "dev-landing").
resource "aws_s3_bucket" "data" {
  for_each = local.buckets

  bucket = each.value

  tags = merge(local.common_tags, {
    Environment = split("-", each.key)[0] # "dev" ou "prd"
    Layer       = split("-", each.key)[1] # "landing", "bronze" ou "silver"
  })
}

# Bloqueia todo acesso público em cada bucket.
# Dados do pipeline são internos e nunca devem ser expostos publicamente.
resource "aws_s3_bucket_public_access_block" "data" {
  for_each = aws_s3_bucket.data

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Criptografia server-side AES256 (gerenciada pela AWS, sem custo adicional).
# Protege os dados em repouso sem necessidade de gerenciar chaves KMS.
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  for_each = aws_s3_bucket.data

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
