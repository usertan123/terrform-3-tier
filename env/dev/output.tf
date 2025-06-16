output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_sg_id" {
  value = module.vpc.vpc_sg_id
}
output "db_subnet" {
  value = module.vpc.private_subnet_ids.db_subnet
}
output "app_subnet" {
  value = module.vpc.private_subnet_ids.app_subnet
}

output "rds_username" {
  value     = module.rds.rds_username
  sensitive = true
}

output "rds_password" {
  value     = module.rds.rds_password
  sensitive = true
}
output "rds_endpoint" {
  value = module.rds.rds_endpoint
}
output "app_alb_dns" {
  value = module.asg.app_alb_dns
}
output "web_alb_dns" {
  value = module.asg.web_alb_dns
}