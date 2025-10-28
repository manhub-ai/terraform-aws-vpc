resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = merge (
    local.common_tags,
    var.vpc_tags,
    {
        Name = local.common_name_suffix
    }
  )
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge (
    local.common_tags,
    var.igw_tags,
    {
        Name = local.common_name_suffix
    }
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]
  map_public_ip_on_launch = true
  
  tags = merge (
    var.public_subnet_tags,
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-public-${local.az_names[count.index]}" #roboshop-dev-public-us-east-1
    }
  )
}

resource "aws_subnet" "private" {
  count = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]
  
  tags = merge (
    var.private_subnet_tags,
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-private-${local.az_names[count.index]}" #roboshop-dev-private-us-east-1
    }
  )
}

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]
  
  tags = merge (
    var.database_subnet_tags,
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-database-${local.az_names[count.index]}" #roboshop-dev-database-us-east-1
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  
  tags = merge (
    local.common_tags,
    var.public_route_table_tags,
    {
        Name = "${local.common_name_suffix}-public"
    }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  
  tags = merge (
    local.common_tags,
    var.private_route_table_tags,
    {
        Name = "${local.common_name_suffix}-private"
    }
  )
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  
  tags = merge (
    local.common_tags,
    var.database_route_table_tags,
    {
        Name = "${local.common_name_suffix}-database"
    }
  )
}

resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = "aws_internet_gatewat.main.id"
}

resource "aws_eip" "nat" {
  domain   = "vpc"
  tags = merge (
    local.common_tags,
    var.eip_tags,
    {
        Name = "${local.common_name_suffix}-nat"
    }
  )
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge (
    var.nat_gatway_tags,
    local.common_tags,
    {
        Name = "${local.common_name_suffix}"
    }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = "aws_nat_gatway.nat.id"
}

resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = "aws_nat_gatway.nat.id"
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.bar.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.bar.id
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.bar.id
}