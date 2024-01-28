variable "mssql_login_pwd" {
  type      = string
  sensitive = true
}

variable "mongodb_connection_string" {
  type      = string
  sensitive = true
}

variable "ecs_containers" {
  description = "Propriedades para as imagens de cada microsserviço"
  type = map(object({
    image     = string
    db_host   = string
    db_schema = string
  }))


  default = {
    "pedido_service" = {
      image     = "258775715661.dkr.ecr.us-east-2.amazonaws.com/sgr-service-pedido"
      db_host   = "sgr-rds-instance-pedido.c5c6gu62ikas.us-east-2.rds.amazonaws.com"
      db_schema = "sgr_database_pedido"
    },
    "producao_service" = {
      image     = "258775715661.dkr.ecr.us-east-2.amazonaws.com/sgr-service-producao"
      db_host   = "sgr-rds-instance-producao.c5c6gu62ikas.us-east-2.rds.amazonaws.com"
      db_schema = "sgr_database_producao"
    }
  }

}