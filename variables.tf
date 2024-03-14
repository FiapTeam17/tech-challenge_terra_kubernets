variable "mssql_login_pwd" {
  type      = string
  sensitive = true
}

variable "mongodb_connection_string" {
  type      = string
  sensitive = true
}

variable "aws_access_key_id" {
  type      = string
  sensitive = true
}

variable "aws_secret_access_key" {
  type      = string
  sensitive = true
}
