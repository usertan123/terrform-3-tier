######-------  VPC  -------#######
vpc_cidr_block        = "192.168.0.0/20"
tags                  = "3-tier"
public_subnet_cidr    = ["192.168.1.0/24", "192.168.2.0/24"]
private_subnet_cidr   = ["192.168.3.0/24", "192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24", "192.168.7.0/24", "192.168.8.0/24"]
availability_zones    = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
enable_public_subnets = true
ingress_rules = [{
  port        = 22
  description = "this is for ssh"
  },
  {
    port        = 80
    description = "this is for apacheserver"
  },
  {
    port        = 443
    description = "this is for https"
  },
  {
    port        = 3306
    description = "this is for database"
  },
  {
    port        = 8080
    description = "this is for tomcat"
}]

#####------  RDS  ----#####
identifier              = "studentapp-db"
allocated_storage       = 20
db_name                 = "studentapp"
engine                  = "mariadb"
engine_version          = "10.6.20"
instance_class          = "db.t3.micro"
backup_retention_period = 7
parameter_group_name    = "default.mariadb10.6"
skip_final_snapshot     = true
publicly_accessible     = false

#######--------  ASG  --------#######
instance_type = "t2.micro"