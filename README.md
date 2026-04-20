@"
# DevOps Showcase Project

Complete end-to-end DevOps pipeline built to showcase skills to recruiters.

## Features Demonstrated
- Docker containerization with multi-stage build and non-root user
- GitHub Actions CI/CD pipeline
- DevSecOps with Trivy + Snyk (auto-block on critical vulnerabilities)
- Infrastructure as Code with Terraform (VPC, EC2, S3 remote backend)
- Ready for Kubernetes (Minikube) + Prometheus + Grafana

## Architecture
```mermaid
graph TD
    A[Git Push] --> B[GitHub Actions]
    B --> C{Security Scan}
    C -->|Fail on Critical| D[Block Deployment]
    C -->|Pass| E[Build Docker Image]
    E --> F[Push to Docker Hub]
    F --> G[Deploy to AWS EC2]
# dkikishop-devops
End-to-end DevOps Portfolio Project - Docker, GitHub Actions, Terraform, DevSecOps
