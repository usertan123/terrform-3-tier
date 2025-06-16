variable "db_subnet_ids" {
  type = list(string)
}
variable "vpc_security_groups" {
  type = list(string)
}
variable "identifier" {
  type = string
}
variable "allocated_storage" {
  type = number
}
variable "db_name" {
  type = string
}
variable "engine" {
  type = string
}
variable "engine_version" {
  type = string
}
variable "instance_class" {
  type = string
}
variable "backup_retention_period" {
  type = number
}
variable "parameter_group_name" {
  type = string
}
variable "skip_final_snapshot" {
  type = bool
}
variable "publicly_accessible" {
  type = bool
}
variable "tags" {
  type = string
}
