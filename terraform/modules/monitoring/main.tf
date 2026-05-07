resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "${var.environment}-app-logs"
  retention_in_days = var.environment == "production" ? 30 : 7
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "devops-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Metrics"
        }
      }
    ]
  })
}