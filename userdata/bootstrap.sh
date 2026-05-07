#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting bootstrap for ${environment} environment"

# Update system
yum update -y
yum install -y docker curl wget jq

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start Docker
systemctl enable docker
systemctl start docker

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U amazon-cloudwatch-agent.rpm

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60,
        "totalcpu": true
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["disk_used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["/"]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "${environment}-app-logs",
            "log_stream_name": "{instance_id}-messages",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/docker-container.log",
            "log_group_name": "${environment}-app-logs",
            "log_stream_name": "{instance_id}-app",
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

# REMOVE OR COMMENT OUT THE DOCKER LOGIN SECTION
# Your image is public on Docker Hub, so no login needed
# docker login -u ${docker_username} -p ${docker_password}

# Pull latest image
docker pull ${docker_image}

# Stop and remove old container
docker stop app-container || true
docker rm app-container || true

# Run new container
docker run -d \
  --name app-container \
  --restart always \
  -p 3000:3000 \
  -e NODE_ENV=${environment} \
  ${docker_image}

# Log container output
docker logs -f app-container >> /var/log/docker-container.log 2>&1 &

# Health check
sleep 10
if curl -f http://localhost:3000/health; then
  echo "✅ Application started successfully"
else
  echo "❌ Application health check failed"
  exit 1
fi

echo "Bootstrap completed for ${environment}"