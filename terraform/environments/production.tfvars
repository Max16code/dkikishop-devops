# Production environment (triggered by 'main' branch)
environment      = "production"
instance_type    = "t3.medium"
min_size         = 2
max_size         = 10
desired_capacity = 2

# Production optimizations
enable_detailed_monitoring = true
log_retention_days         = 30
enable_multi_az            = true