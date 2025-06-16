##### -------------    AWS_VPC    ------------######
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    # Name = "${var.tags}-vpc"
    Name = join("-", [var.tags, "vpc"])
  }
  ##### -------------    AWS_IGW    ------------######
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.tags}-igw"
  }
}

resource "aws_eip" "nat-eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.gw]
  tags = {
    # Name = "${var.tags}-eip"
    Name = format("%s-eip", var.tags)
  }
}

##########---------------  NAT_GW  ------------------##########
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public_subnet[1].id
  depends_on    = [aws_internet_gateway.gw]
  tags = {
    Name = "${var.tags}-nat-gw"
  }
}

##### -------------    AWS_public_subnet    ------------######
resource "aws_subnet" "public_subnet" {
  count                   = var.enable_public_subnets ? length(var.public_subnet_cidr) : 0
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[count.index]


  tags = {
    Name = "${var.tags}-public-subnet-${count.index + 1}"
  }
}

##### -------------    AWS_private_subnet    ------------######
# locals {
#   private_chunks = chunklist(var.private_subnet_cidr,2)
#   web_subnet_cidr = local.private_chunks[0]
#   app_subnet_cidr = local.private_chunks[1]
# }

locals {
  web_subnet_cidr = slice(var.private_subnet_cidr, 0, 2)
  app_subnet_cidr = slice(var.private_subnet_cidr, 2, 4)
  db_subnet_cidr  = slice(var.private_subnet_cidr, 4, 6)
  web_subnet_az_map = {
    for i in range(length(local.web_subnet_cidr)) :
    i => {
      cidr = local.web_subnet_cidr[i]
      az   = var.availability_zones[i % length(var.availability_zones)]
    }
  }

  app_subnet_az_map = {
    for i in range(length(local.app_subnet_cidr)) :
    i => {
      cidr = local.app_subnet_cidr[i]
      az   = var.availability_zones[i % length(var.availability_zones)]
    }
  }

  db_subnet_az_map = {
    for i in range(length(local.db_subnet_cidr)) :
    i => {
      cidr = local.db_subnet_cidr[i]
      az   = var.availability_zones[i % length(var.availability_zones)]
    }
  }
  # web_subnet_az_map = {
  # for i, cidr in local.web_subnet_cidr :
  # cidr => var.availability_zones[i % length(var.availability_zones)]
  # }
  # app_subnet_az_map = {
  # for i, cidr in local.app_subnet_cidr :
  # cidr => var.availability_zones[i % length(var.availability_zones)]
  # }
  # db_subnet_az_map = {
  # for i, cidr in local.db_subnet_cidr :
  # cidr => var.availability_zones[i % length(var.availability_zones)]
  # }
}
resource "aws_subnet" "web_subnet" {
  #   for_each = toset(chunklist(var.private_subnet_cidrs, 2)[0]) -----------directly with chunlist
  #   for_each = toset(slice(var.private_subnet_cidrs, 0, 2))  ----------directly using slice
  #   for_each = toset(local.web_subnet_cidr) -------converted list to set (we avoid this because we converted into map for both cidr and az)
  for_each          = local.web_subnet_az_map
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az


  tags = {
    Name = "${var.tags}-web_subnet-${each.key + 1}"
  }
}
resource "aws_subnet" "app_subnet" {
  #   for_each = toset(chunklist(var.private_subnet_cidrs, 2)[1])
  #   for_each = toset(slice(var.private_subnet_cidrs, 3, 5))
  #   for_each = toset(local.web_subnet_cidr)
  for_each          = local.app_subnet_az_map
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.tags}-app_subnet-${each.key + 1}"
  }
}
resource "aws_subnet" "db_subnet" {
  #   for_each = toset(chunklist(var.private_subnet_cidrs, 2)[1])
  #   for_each = toset(slice(var.private_subnet_cidrs, 3, 5))
  #   for_each = toset(local.db_subnet_cidr)
  for_each          = local.db_subnet_az_map
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.tags}-db_subnet-${each.key + 1}"
  }
}

########## ----------  AWS_RT  ---------  ##########
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.tags}-public_RT"
  }
}
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "${var.tags}-private_RT"
  }
}


##########--------------  Subnet_assocciations  --------------##########
resource "aws_route_table_association" "public_subnet_association" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "web_subnet_association" {
  for_each = aws_subnet.web_subnet
  # subnet_id      = aws_subnet.web_subnet[count.index].id
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "app_subnet_association" {
  for_each = aws_subnet.app_subnet
  # subnet_id      = aws_subnet.app_subnet[count.index].id
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "db_subnet_association" {
  for_each = aws_subnet.db_subnet
  # subnet_id      = aws_subnet.db_subnet[count.index].id
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
}

##########-------------  SECURITY_GROUP  -------------##########
resource "aws_security_group" "sg" {
  name        = "${var.tags}-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  depends_on  = [aws_vpc.main]
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${var.tags}-sg"
  }
}
