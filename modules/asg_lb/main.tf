data "external" "rds_credentials" {
  program = ["bash", "-c", "vault kv get -format=json secret/rds | jq -r '{username: .data.data.username, password: .data.data.password}'"]
}

# # Replace with your actual RDS module output
# output "rds_endpoint" {
#   value = module.rds.endpoint
# }


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = format("%s-key", var.tags)
  public_key = tls_private_key.example.public_key_openssh

  // Store the private key in a local file

  provisioner "local-exec" {
    command = "echo '${tls_private_key.example.private_key_pem}' > ${path.module}/demo.pem && chmod 400 ${path.module}/demo.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/demo.pem"
  }
}

# -----------------------------
# Target Group
# -----------------------------
resource "aws_lb_target_group" "app" {
  name     = "${var.tags}-app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
    port                = "traffic-port"

  }
  tags = {
    Name = "${var.tags}-app-tg"
  }
}

# -----------------------------
# Load Balancer and Listener
# -----------------------------

resource "aws_lb" "app_alb" {
  name               = "${var.tags}-app-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = var.alb_security_group_id
  subnets            = var.app_subnet_ids
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# -----------------------------
# User Data Template
# -----------------------------
# data "local_file" "mysql_connector" {
#   filename = "${path.module}/mysql-connector.jar"
# }

data "template_file" "app_user_data" {
  template = file("${path.module}/user_data.sh.tpl")

  vars = {
    db_endpoint = replace(var.rds_endpoint, ":3306", "")
    db_user     = data.external.rds_credentials.result.username
    db_pass     = data.external.rds_credentials.result.password
    # mysql_connector = data.local_file.mysql_connector.content
  }
}

# -----------------------------
# Launch Template
# -----------------------------
resource "random_id" "suffix" {
  byte_length = 2 # 2 bytes = 4 hex characters
}

resource "aws_launch_template" "app" {
  name_prefix   = "app-launch-template"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.generated_key.id
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 20
      volume_type           = "gp2"
      delete_on_termination = true
      # iops                  = lookup(var.ebs, "iops", "null")
      # encrypted             = lookup(var.ebs, "encrypted", true)
    }
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = var.security_group_ids

  }
  # placement {
  #   availability_zone = 
  # }
  user_data = base64encode(data.template_file.app_user_data.rendered)

  # vpc_security_group_ids = var.security_group_ids
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.tags}-app-server-${random_id.suffix.hex}"
    }
  }
}

# -----------------------------
# Auto Scaling Group
# -----------------------------

resource "aws_autoscaling_group" "app" {
  name                      = "app-asg"
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier       = var.app_subnet_ids

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app.arn]
  force_delete      = true

  tag {
    key                 = "Name"
    value               = "${var.tags}-app-server-${random_id.suffix.hex}"
    propagate_at_launch = true
  }
}

# -----------------------------
# CloudWatch Scaling Policies
# -----------------------------

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-util-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu-util-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}




#######........   WEB_SERVER_ALB_&_TG  ........########
resource "aws_lb_target_group" "web" {
  name     = "${var.tags}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.tags}-web-tg"
  }
}
resource "aws_lb_target_group_attachment" "web_attachments" {
  count            = length(var.web_instance_ids)
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = var.web_instance_ids[count.index]
  port             = 80
}

resource "aws_lb" "web_alb" {
  name               = "${var.tags}-web-alb"
  load_balancer_type = "application"
  internal = false
  security_groups    = var.alb_security_group_id
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.tags}-web-alb"
    # Environment = "dev"
  }
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

