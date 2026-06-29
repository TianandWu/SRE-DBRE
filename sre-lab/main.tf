provider "aws" {
    region = "ap-northeast-1"
}


/*
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


resource "aws_security_group" "ALB_sg" {
  name        = "ALB-sg"
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
  name        = "EC2-sg"
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


data "aws_ami" "web" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
# ai 說這樣拿 ami 比較舒服，我就試試看
# 如果今天是用 docker build 就要使用 Data Source AMI + user_data maybe 如下 （較慢 build 需要時間）：
#bash#!/bin/bash
# 1. 幫這台新機器安裝 Docker
#sudo amazon-linux-extras install docker -y
#sudo systemctl start docker
#sudo systemctl enable docker

# 2. 登入您的 Docker 倉庫 (例如 AWS ECR 或 Docker Hub)
# 3. 把您 build 好的 image 抓下來
#docker pull ://amazonaws.com

# 4. 把容器跑起來並對外開 Port 80
#docker run -d -p 80:8080 ://amazonaws.com

#或者 預先做成客製化 AMI  並將上面的 owners=["self"]  （較快）

resource "aws_launch_template" "web_lt" {
  name          = "web-launch-template-lt"
  image_id      = data.aws_ami.web.id
  instance_type = "t2.micro"


  vpc_security_group_ids = [aws_security_group.EC2_sg.id]

  user_data = base64encode(file("user_data.sh"))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "web-server"
    }
  } 
}

#launch_template 名稱,ami,機器型號,security group,開啟跑的 data (如果 docker build image 應該不用),tag name


resource "aws_autoscaling_group" "web_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  vpc_zone_identifier  = [aws_subnet.PublicA.id, aws_subnet.PublicB.id]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest" #看需不需要搭配 instance_refresh 來使用最新的 launch_template,暫時先不動,原因也沒新版（？
  }

  tag {
    key                 = "Name"
    value               = "web-server"
    propagate_at_launch = true
  }
}

# autoscaling 基本線上要幾台 desired_capacity ,當異常發生最大給多少最少給多少,可以建在哪些 zone 上, 吃的 launch_template,tag name
# When using ELB as the health_check_type, health_check_grace_period is required.
# 簡單說沒有 load balancer 選 ec2 有就選 elb

resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false 
  #if ture, it will be a internal load balancer, if false, it will be a internet facing load balancer

  load_balancer_type = "application" 
  # default is application, application = http/https, network = tcp/udp, gateway = ip 封包

  security_groups    = [aws_security_group.ALB_sg.id]
  subnets            = [aws_subnet.PublicA.id, aws_subnet.PublicB.id]

  tags = {
    Name = "web-alb"
  }
}

# alb name,internal ,load_balancer_type,security group,subnet,tag name 

resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.test.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }

  tags = {
    Name = "web-tg"
  }
}

# 主要針對 health check 備註,對 / 跟目錄底下機器做偵測,interval 檢查頻率(s) , healthy_threshold 成功幾次算健康,
# unhealthy_threshold 失敗幾次不健康(移除),matcher result 在這些內算正常，但看網路上這些東西都會搭配前端一個 health_check (?)


resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
#    forward {
#        target_group {
#        arn    = aws_lb_target_group.blue.arn
#        weight = 90  # 90% 流量去舊版
#        }
#        target_group {
#        arn    = aws_lb_target_group.green.arn
#        weight = 10  # 10% 流量去新版試水溫
#        }
#    }
    target_group_arn = aws_lb_target_group.web_tg.arn
  }

}   

# .arn 是為了拿 aws 識別碼 (PK) ,type 動作類型有五種這邊用 forward 是為了轉發流量監聽用，進階用法 金絲雀發布（Canary Release）或流量分流（Traffic Shifting）


resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  lb_target_group_arn    = aws_lb_target_group.web_tg.arn
}

#region- （可選）此資源將要管理的區域。預設為提供程序配置中設定的區域。
#autoscaling_group_name- （必填）要與 ELB 相關的 ASG 名稱。
#elb- （可選）ELB 的名稱。
#lb_target_group_arn- （可選）負載平衡器目標群組的 ARN。



*/


#####################################還沒寫
# alb -> route 53 使用
# monitoring  => 寫規則監控 ALB
# readme    => 寫架構,使用,測試,故障演練,清理,已知限制 （待確認，不太確定
# 完成後將所有的 resource 都改用 module 呈現