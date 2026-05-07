# Staging environment (triggered by 'develop' branch)
environment      = "staging"
instance_type    = "t3.micro"
min_size         = 1
max_size         = 3
desired_capacity = 1

# Staging optimizations
enable_detailed_monitoring = false
log_retention_days         = 7