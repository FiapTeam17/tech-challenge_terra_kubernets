resource "kubernetes_manifest" "configmap_sgr_configmap" {
  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "database_name" = "sgr_database"
      "database_password" = "ADICIONAR_SENHA_GIT_SECRETS"
      "database_port" = "3306"
      "mercado_pago_token" = "TOKEN_GIT_SECRETS"
    }
    "kind" = "ConfigMap"
    "metadata" = {
      "name" = "sgr-configmap"
    }
  }
}
