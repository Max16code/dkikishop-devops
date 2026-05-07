#!/bin/bash
set -e

echo "Starting bootstrap for ${environment} environment"

# Update system
yum update -y
yum install -y docker curl wget jq

# Start Docker
systemctl enable docker
systemctl start docker

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

# Health check
sleep 10
if curl -f http://localhost:3000/health; then
  echo "✅ Application started successfully"
else
  echo "❌ Application health check failed"
  exit 1
fi

echo "Bootstrap completed for ${environment}"
