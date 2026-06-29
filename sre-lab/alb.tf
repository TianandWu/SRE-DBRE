resource "aws_lb" "web-alb" {
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

resource "aws_lb_target_group" "web-tg" {
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
  load_balancer_arn = aws_lb.web-alb.arn
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
    target_group_arn = aws_lb_target_group.web-tg.arn
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



