resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = merge(
    local.common_tags,
    var.vpc_tags,
    {
        Name = local.common_name_suffix
    }
  )
}

#IGW
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        local.common_tags,
        var.igw_tags,
        {
            Name = local.common_name_suffix
        }
    )
}

#public subnets

resource "aws_subnet" "public" {
  count = length(var.public_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_cidr[count.index]
  availability_zone = local.az-names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
        local.common_tags,
        var.public_cidr_tags,
        {
            Name = "${local.common_name_suffix}-public-${local.az-names[count.index]}" #roboshop-dev-public-us-east-1a/1b
        }
    )
}

#private subnets

resource "aws_subnet" "private" {
  count = length(var.private_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_cidr[count.index]
  availability_zone = local.az-names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
        local.common_tags,
        var.private_cidr_tags,
        {
            Name = "${local.common_name_suffix}-private-${local.az-names[count.index]}" #roboshop-dev-private-us-east-1a/1b
        }
    )
}

resource "aws_subnet" "database" {
  count = length(var.database_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_cidr[count.index]
  availability_zone = local.az-names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
        local.common_tags,
        var.database_cidr_tags,
        {
            Name = "${local.common_name_suffix}-database-${local.az-names[count.index]}" #roboshop-dev-database-us-east-1a/1b
        }
    )
}

#public-route-table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-public"
    }
  )
}

# Public Route
resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}


# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-private"
    }
  )
}

# Database Route Table
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-database"
    }
  )
}

# Elastic IP
resource "aws_eip" "nat" {
  domain   = "vpc"
}


# NAT gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name_suffix}"
    }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

# Private egress route through NAT
resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

# Database egress route through NAT
resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}


resource "aws_route_table_association" "public" {
  count = length(var.public_cidr)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_cidr)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count = length(var.database_cidr)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}