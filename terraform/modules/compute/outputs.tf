output "asg_name" {
  value = aws_autoscaling_group.app.name
}

output "alb_arn_suffix" {
  value = element(split("/", var.target_group_arn), length(split("/", var.target_group_arn)) - 1)
}