data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    # values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
resource "aws_instance" "bastion_host" {
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.instance_type
  subnet_id               = var.public_subnet_id[0]
  vpc_security_group_ids  = [var.vpc_sg_id]
  disable_api_termination = true
  monitoring              = false
  key_name                = var.public_key_name
  user_data = templatefile("${path.module}/user_data_bastion.tpl", {
    private_key_pem = var.private_key_pem
  })
  tags = {
    Name = "${var.tags}-bastion-host"
  }
}


resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.web_subnet_ids[count.index]
  vpc_security_group_ids = [var.vpc_sg_id]
  count                  = length(var.web_subnet_ids)
  key_name               = var.public_key_name
  user_data = templatefile("${path.module}/user_data_web.tpl", {
    # app_alb_dns = module.app_alb.dns_name
    app_alb_dns = var.app_alb_dns
    index_html  = file("${path.module}/index.html")
  })

  tags = {
    Name = "${var.tags}-web-server-${count.index + 1}"
  }
}

data "external" "rds_credentials" {
  program = ["bash", "-c", "vault kv get -format=json secret/rds | jq -r '{username: .data.data.username, password: .data.data.password}'"]
}
data "local_file" "studentapp_sql" {
  filename = "${path.module}/studentapp.sql"
}

data "template_file" "db_user_data" {
  template = file("${path.module}/user_data_db.tpl")

  vars = {
    db_endpoint = replace(var.rds_endpoint, ":3306", "")
    db_user     = data.external.rds_credentials.result.username
    db_pass     = data.external.rds_credentials.result.password
    student_sql = base64encode(data.local_file.studentapp_sql.content)
  }
}

resource "aws_instance" "db_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.db_subnet_ids[count.index]
  vpc_security_group_ids = [var.vpc_sg_id]
  count                  = length(var.db_subnet_ids)
  key_name               = var.public_key_name
  user_data              = base64encode(data.template_file.db_user_data.rendered)
  tags = {
    Name = "${var.tags}-db-server-${count.index + 1}"
  }
}





