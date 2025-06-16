variable "vpc_cidr_block" {
  type = string
}
variable "tags" {
  type = string
}
variable "enable_public_subnets" {
  type = bool
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
variable "ingress_rules" {
  type = list(object({
    port        = number
    description = string
  }))
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

# variable "vpc_id" {
#   type = string
# }
# variable "alb_security_group_id" {
#   type = list(any)
# }
# variable "app_subnet_ids" {
#   type = list(string)
# }
variable "instance_type" {
  type = string
}
# variable "security_group_ids" {
#   type = list(string)
# }
# variable "public_subnet_id" {
#   type = list(string)
# }
# variable "vpc_sg_id" {
#   type = string
# }
# variable "public_key_name" {
#   type = string
# }
# variable "web_subnet_ids" {
#   type = list(string)
# }
# variable "db_subnet_ids" {
#   type = list(string)
# }
# variable "app_alb_dns" {
#   type = string
# }
# variable "rds_endpoint" {
#   type = string
# }