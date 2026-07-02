
resource "aws_vpc" "test" {
  cidr_block = var.vpc_cidr 
  tags = {
    Name = var.vpc_name
  }
}



resource "aws_subnet" "PublicA" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = var.subnet_cidr_public_a
  availability_zone = var.az_public_a
  tags = {
    Name = var.subnet_name_public_a
  }
}


resource "aws_subnet" "PublicB" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = var.subnet_cidr_public_b
  availability_zone = var.az_public_b
  tags = {
    Name = var.subnet_name_public_b
  }
}






resource "aws_internet_gateway" "test" {
  vpc_id = aws_vpc.test.id
  tags = {
    Name = var.gateway_name
  }
}




resource "aws_route_table" "test" {
  vpc_id = aws_vpc.test.id

  route {
    cidr_block = var.route_table_cidr
    gateway_id = aws_internet_gateway.test.id
  }

  tags = {
    Name = var.route_table_name
  }
}


resource "aws_route_table_association" "PublicA" {
  subnet_id      = aws_subnet.PublicA.id
  route_table_id = aws_route_table.test.id
}

resource "aws_route_table_association" "PublicB" {
  subnet_id      = aws_subnet.PublicB.id
  route_table_id = aws_route_table.test.id
}

# vpc 就很直觀用 resoruce create (基礎課的東西)
# subnet,igw 都是從 vpc_id 給下來的在做劃分,router 多了一個 gateway_id,route_table 多一個 gateway_id 串起來
# route_table_association 是把 route_table 跟 subnet 做關聯,這樣就可以讓 subnet 連到 igw





module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = [var.az_public_a, var.az_public_b]
  #private_subnets = [] 
  public_subnets  = [var.subnet_cidr_public_a, var.subnet_cidr_public_b]

  enable_nat_gateway = false #我的 lab 沒 
  enable_vpn_gateway = false #我的 lab 沒

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}


# 當初架構是想說 ec2 -> alb -> internet ,後面再看按完整架構是不是該加上 private subnet ,nat gateway ,vpn gateway -> 畢竟 module 有
# 先回去學三元運算 -> github source code 不然看不懂 module