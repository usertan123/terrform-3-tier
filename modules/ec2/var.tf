variable "instance_type" {
  type = string
}
variable "public_subnet_id" {
  type = list(string)
}
variable "vpc_sg_id" {
  type = string
}
variable "public_key_name" {
  type = string
}
variable "tags" {
  type = string
}
variable "web_subnet_ids" {
  type = list(string)
}
variable "db_subnet_ids" {
  type = list(string)
}
variable "app_alb_dns" {
  type = string
}
variable "rds_endpoint" {
  type = string
}
variable "private_key_pem" {
  type      = string
  sensitive = true
}