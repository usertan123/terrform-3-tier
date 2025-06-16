variable "vpc_cidr_block" {
  type = string
}
variable "tags" {
  type = string
}
variable "public_subnet_cidr" {
  type = list(string)
}
variable "private_subnet_cidr" {
  type = list(string)
}
variable "availability_zones" {
  type = list(string)
}
variable "enable_public_subnets" {
  type = bool
}
variable "ingress_rules" {
  type = list(object({
    port        = number
    description = string
  }))
}