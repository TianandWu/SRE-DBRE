
resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "test-vpc"
  }
}


resource "aws_subnet" "PublicA" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name = "PublicA"
  }
}

resource "aws_subnet" "PublicB" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name = "PublicB"
  }
}

resource "aws_internet_gateway" "test" {
  vpc_id = aws_vpc.test.id
  tags = {
    Name = "test-igw"
  }
}


resource "aws_route_table" "test" {
  vpc_id = aws_vpc.test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test.id
  }

  tags = {
    Name = "test-rt"
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

