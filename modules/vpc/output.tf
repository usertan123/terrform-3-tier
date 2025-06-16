output "vpc_id" {
  value = aws_vpc.main.id
}
output "public_subnet_id" {
  value = {
    public_subnets = [
      aws_subnet.public_subnet[0].id,
      aws_subnet.public_subnet[1].id
    ]
  }
}
output "private_subnet_ids" {
  value = {
    web_subnet = [
      aws_subnet.web_subnet[0].id,
      aws_subnet.web_subnet[1].id,
    ],
    app_subnet = [
      aws_subnet.app_subnet[0].id,
      aws_subnet.app_subnet[1].id,
    ],
    db_subnet = [
      aws_subnet.db_subnet[0].id,
      aws_subnet.db_subnet[1].id,
    ],
  }
}

output "vpc_sg_id" {
  value = aws_security_group.sg.id
}