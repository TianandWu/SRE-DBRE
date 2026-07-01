resource "aws_sns_topic" "alerts" {
  name = "system-alerts-topic"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "zxc91137@gmail.com" 
}

#上面這段是告警轉發，可以透過 n8n 或 aws Lambda 轉發 tg 比較好維運 (?




resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "unhealthy-instances-alarm"
  alarm_description   = "當 Target Group 中出現不健康的 EC2 時，觸發告警。"

  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Average"

  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 1
  period              = 60

  dimensions = {
    TargetGroup  = aws_lb_target_group.web_tg.arn_suffix
    LoadBalancer = aws_lb.web_alb.arn_suffix
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  insufficient_data_actions = []
}


resource "aws_autoscaling_policy" "cpu_tracking" {
  name                   = "cpu-target-tracking-policy"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0

    estimated_instance_warmup = 180
  }
}

