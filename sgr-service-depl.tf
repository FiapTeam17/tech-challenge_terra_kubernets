resource "kubernetes_manifest" "deployment_sgr_api" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "Deployment"
    "metadata" = {
      "labels" = {
        "app" = "sgr-deployment"
      }
      "name" = "sgr-api"
      "namespace" = "default"
    }
    "spec" = {
      "replicas" = 2
      "selector" = {
        "matchLabels" = {
          "app" = "sgr-deployment"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "sgr-deployment"
          }
        }
        "spec" = {
          "containers" = [
            {
              "env" = [
                {
                  "name" = "DB_HOST"
                  "value" = "mysql-ext-service"
                },
                {
                  "name" = "token"
                  "valueFrom" = {
                    "configMapKeyRef" = {
                      "key" = "mercado_pago_token"
                      "name" = "sgr-configmap"
                    }
                  }
                },
              ]
              "image" = "sgr-api"
              "imagePullPolicy" = "Never"
              "name" = "sgr-service"
              "ports" = [
                {
                  "containerPort" = 8083
                },
              ]
            },
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "service_sgr_api_service" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "name" = "sgr-api-service"
    }
    "spec" = {
      "ports" = [
        {
          "port" = 80
          "protocol" = "TCP"
          "targetPort" = 8083
        },
      ]
      "selector" = {
        "app" = "sgr-deployment"
      }
      "type" = "LoadBalancer"
    }
  }
}
