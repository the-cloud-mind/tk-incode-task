variable "postgres_backup_retention_period" {
  type    = number
  default = 7
}
variable "postgres_engine_version" {
  type    = string
  default = "17.4"
}
