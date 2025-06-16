variable "tags" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "alb_security_group_id" {
  type = list(any)
}
variable "app_subnet_ids" {
  type = list(string)
}
variable "instance_type" {
  type = string
}
variable "security_group_ids" {
  type = list(string)
}
variable "rds_endpoint" {
  type = string
}
variable "web_instance_ids" {
  type = list(string)
}
variable "public_subnet_ids" {
  type = list(string)
}