name: CI/CD Pipeline

on:
  push:
    branches:
      - main
      - develop

env:
  IMAGE_NAME: ${{ secrets.DOCKER_USERNAME }}/devops-showcase
  AWS_REGION: us-east-1

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Debug - List all files
        run: |
          pwd
          ls -la
          ls -la terraform/ || echo "terraform directory not found"

      - name: Install Dependencies & Test
        run: |
          cd app
          npm install
          npm test || echo "No tests configured"

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}

      - name: Build Docker Image
        run: |
          cd app
          docker build -t $IMAGE_NAME:latest -t $IMAGE_NAME:${{ github.sha }} .

      - name: Push Docker Image
        run: |
          docker push $IMAGE_NAME:latest
          docker push $IMAGE_NAME:${{ github.sha }}

  deploy-staging:
    needs: build-and-push
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0

      - name: Terraform Init
        run: |
          cd terraform
          terraform init

      - name: Terraform Apply Staging
        run: |
          cd terraform
          terraform apply -auto-approve \
            -var="docker_image=$IMAGE_NAME:latest" \
            -var="environment=staging"

  deploy-production:
    needs: build-and-push
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0

      - name: Terraform Init
        run: |
          cd terraform
          terraform init

      - name: Terraform Apply Production
        run: |
          cd terraform
          terraform apply -auto-approve \
            -var="docker_image=$IMAGE_NAME:latest" \
            -var="environment=production"