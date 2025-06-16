resource "aws_db_subnet_group" "db_subnet" {
  name       = "rds-3-tier"
  subnet_ids = var.db_subnet_ids
}
# data "external" "rds_creds" {
#   program = ["${path.module}/get_rds_credentials.sh"]
# }

# nohup vault server -dev > vault.log 2>&1 &
# vim ~/.bashrc 
# enter token from vault.log 
# source ~/.bashrc 
# vault secrets list 
# vault kv get secret/rds
# EX. vault kv put secret/rds username=admin password=admin123 
data "external" "rds_credentials" {
  program = ["bash", "-c", "vault kv get -format=json secret/rds | jq -r '{username: .data.data.username, password: .data.data.password}'"]
}



resource "aws_db_instance" "database" {
  identifier              = "${var.identifier}-${var.tags}"
  allocated_storage       = var.allocated_storage
  db_name                 = var.db_name
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  username                = data.external.rds_credentials.result.username
  password                = data.external.rds_credentials.result.password
  backup_retention_period = var.backup_retention_period
  parameter_group_name    = var.parameter_group_name
  skip_final_snapshot     = var.skip_final_snapshot
  publicly_accessible     = var.publicly_accessible
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids  = var.vpc_security_groups


}


