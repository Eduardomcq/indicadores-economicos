locals {
  # Ambientes e camadas que compõem a arquitetura medalhão no S3.
  # A camada gold não está aqui porque será servida pelo PostgreSQL.
  environments = ["dev", "prd"]
  layers       = ["landing", "bronze", "silver"]

  # Gera um mapa com todas as combinações ambiente x camada.
  # Resultado: { "dev-landing" = "dev-emcq-indicadores-economicos-landing", ... }
  buckets = {
    for pair in setproduct(local.environments, local.layers) :
    "${pair[0]}-${pair[1]}" => "${pair[0]}-emcq-indicadores-economicos-${pair[1]}"
  }

  common_tags = {
    Project   = "indicadores-economicos"
    ManagedBy = "terraform"
  }
}
