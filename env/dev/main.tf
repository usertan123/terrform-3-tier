module "vpc" {
  source                = "../../modules/vpc"
  vpc_cidr_block        = var.vpc_cidr_block
  tags                  = var.tags
  enable_public_subnets = var.enable_public_subnets
  public_subnet_cidr    = var.public_subnet_cidr
  private_subnet_cidr   = var.private_subnet_cidr
  availability_zones    = var.availability_zones
  ingress_rules         = var.ingress_rules
}

module "rds" {
  source                  = "../../modules/rds"
  identifier              = var.identifier
  allocated_storage       = var.allocated_storage
  db_name                 = var.db_name
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  backup_retention_period = var.backup_retention_period
  parameter_group_name    = var.parameter_group_name
  skip_final_snapshot     = var.skip_final_snapshot
  publicly_accessible     = var.publicly_accessible
  tags                    = var.tags
  db_subnet_ids           = module.vpc.private_subnet_ids.db_subnet
  vpc_security_groups     = [module.vpc.vpc_sg_id]
}

module "asg" {
  source                = "../../modules/asg_lb"
  vpc_id                = module.vpc.vpc_id
  alb_security_group_id = [module.vpc.vpc_sg_id]
  app_subnet_ids        = module.vpc.private_subnet_ids.app_subnet
  instance_type         = var.instance_type
  security_group_ids    = [module.vpc.vpc_sg_id]
  rds_endpoint          = module.rds.rds_endpoint
  web_instance_ids = module.ec2.web_instance_ids
  public_subnet_ids = module.vpc.public_subnet_id.public_subnets
  tags                  = var.tags
}

module "ec2" {
  source           = "../../modules/ec2"
  instance_type    = var.instance_type
  vpc_sg_id        = module.vpc.vpc_sg_id
  tags             = var.tags
  app_alb_dns      = module.asg.app_alb_dns
  rds_endpoint     = module.rds.rds_endpoint
  public_key_name  = module.asg.asg_key_name
  db_subnet_ids    = module.vpc.private_subnet_ids.db_subnet
  public_subnet_id = module.vpc.public_subnet_id.public_subnets
  web_subnet_ids   = module.vpc.private_subnet_ids.web_subnet
  private_key_pem  = module.asg.asg_private_key


}