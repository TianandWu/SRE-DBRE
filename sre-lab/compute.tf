
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

resource "aws_launch_template" "web-lt" {
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


resource "aws_autoscaling_group" "web-asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  vpc_zone_identifier  = [aws_subnet.PublicA.id, aws_subnet.PublicB.id]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web-lt.id
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
