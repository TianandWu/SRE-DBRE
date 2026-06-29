
resource "aws_security_group" "ALB_sg" {
  name        = "ALB_sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.test.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "EC2_sg" {
  name        = "EC2_sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.test.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.ALB_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#寫個多 zone 的 security group, ALB_sg 只開 80 port 給所有人, EC2_sg 只開 80 port 給 ALB_sg, egress 都給所有人
#思路:基本上不用 variable 就直接寫死，給的東西差不多，主要是 EC2_sg 的 ingress 要給 ALB_sg 使用所以多給了一個 security_groups 