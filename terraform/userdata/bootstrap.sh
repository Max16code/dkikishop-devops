#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting bootstrap for ${environment} environment"

# Update system
yum update -y
yum install -y docker curl wget jq

# Start Docker
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user

# Install CloudWatch Agent
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U amazon-cloudwatch-agent.rpm 2>/dev/null || true

# Configure CloudWatch Agent
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60
  },
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"]
      },
      "mem": {
        "measurement": ["mem_used_percent"]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/docker-container.log",
            "log_group_name": "${environment}-app-logs",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch Agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Clean up old images to force fresh pull
docker system prune -f

# Pull latest image
echo "Pulling image: ${docker_image}"
docker pull ${docker_image}

# Stop and remove old container
docker stop app-container 2>/dev/null || true
docker rm app-container 2>/dev/null || true

# Run new container
docker run -d \
  --name app-container \
  --restart always \
  -p 3000:3000 \
  -e NODE_ENV=${environment} \
  ${docker_image}

# Log container output
docker logs -f app-container 2>&1 | tee -a /var/log/docker-container.log &

# Wait for container to start
sleep 15

# Health check
if curl -f http://localhost:3000/health; then
  echo "✅ Application started successfully"
else
  echo "❌ Application health check failed"
  exit 1
fi

echo "Bootstrap completed for ${environment} at $(date)"