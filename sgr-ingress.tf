resource "kubernetes_manifest" "ingress_sgr_ingress" {
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind" = "Ingress"
    "metadata" = {
      "annotations" = {
        "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      }
      "name" = "sgr-ingress"
    }
    "spec" = {
      "ingressClassName" = "nginx"
      "rules" = [
        {
          "host" = "sgr-api.com"
          "http" = {
            "paths" = [
              {
                "backend" = {
                  "service" = {
                    "name" = "sgr-api-service"
                    "port" = {
                      "number" = 80
                    }
                  }
                }
                "path" = "/"
                "pathType" = "Prefix"
              },
            ]
          }
        },
      ]
    }
  }
}
