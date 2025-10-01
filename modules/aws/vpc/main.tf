# =====================
# 🌐 VPC + Subnet Setup
# ===================== 

# 🚧 Creates the main Virtual Private Cloud
resource "aws_vpc" "this" {
  cidr_block = var.cidr_block

  tags = {
    Name = local.name
  }
}

# 📦 Public Subnets 
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id            = aws_vpc.this.id
  availability_zone = element(var.availability_zones, count.index)
  cidr_block        = element(var.public_subnets, count.index)

  tags = {
    Name = "${local.name}-pub-${element(var.availability_zones, count.index)}"
  }
}

# 🔒 Private Subnets 
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  availability_zone = element(var.availability_zones, count.index)
  cidr_block        = element(var.private_subnets, count.index)

  tags = {
    Name = "${local.name}-pvt-${element(var.availability_zones, count.index)}"
  }
}

# =========================
# 🌍 Internet Gateway Setup
# =========================

# 🌐 Internet Gateway for public subnets (1 per VPC)
resource "aws_internet_gateway" "this" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = {
    Name = local.name
  }
}

# ====================
# 🚪 NAT Gateway Setup
# ====================

# 📤 Elastic IP for NAT Gateway
resource "aws_eip" "this" {
  count = var.enable_nat_gateway == true ? 1 : 0

  domain = "vpc"

  tags = {
    Name = "${local.name}-nat-gw-eip"
  }
}

# 🔁 NAT Gateway for outbound traffic from private subnets
resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway == true ? 1 : 0

  subnet_id     = aws_subnet.public[0].id
  allocation_id = aws_eip.this[0].id

  tags = {
    Name = local.name
  }
}

# =========================
# 🛣️ Route Tables & Routing
# =========================

# 🛣️ Public Route Table
resource "aws_route_table" "public" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name}-pub"
  }
}

# 🔒 Private Route Table
resource "aws_route_table" "private" {
  count = length(var.private_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name}-pvt"
  }
}

# 🌐 Route for Internet Gateway in Public Route Table
resource "aws_route" "public_int_gw_route" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

# 📤 Route for NAT Gateway in Private Route Table
resource "aws_route" "private_nat_gw_route" {
  count = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

# ===========================
# 🔗 Route Table Associations
# ===========================

# 🔗 Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets) > 0 && length(aws_route_table.public) > 0 ? length(aws_subnet.public) : 0

  route_table_id = aws_route_table.public[0].id
  subnet_id      = aws_subnet.public[count.index].id
}

# 🔗 Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private) > 0 && length(aws_route_table.private) > 0 ? length(aws_subnet.private) : 0

  route_table_id = aws_route_table.private[0].id
  subnet_id      = aws_subnet.private[count.index].id
}
