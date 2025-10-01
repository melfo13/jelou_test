# User Management Microservice

A complete Node.js microservice for user management with PostgreSQL database, containerized with Docker, and deployed on AWS EC2 using Terraform.

## Architecture

This project deploys a single EC2 instance containing:
- **Node.js Application**: Express.js REST API for user management
- **PostgreSQL Database**: Local database instance
- **Nginx**: Reverse proxy and load balancer
- **Docker Compose**: Container orchestration

## Features

- User CRUD operations (Create, Read, Update, Delete)
- PostgreSQL database with proper indexing
- Health check endpoints
- CORS configuration
- Docker containerization
- AWS EC2 deployment with Terraform

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Terraform (>= 1.0)
- AWS CLI configured
- SSH key pair

### GitHub Actions CI/CD

This project includes automated CI/CD pipelines:

- **Deploy infrastructure Workflow** (`.github/workflows/terraform-infrastructure.yml`): Automated deployment to AWS
- **Deploy App through Docker Workflow** (`.github/workflows/docker-deploy.yml`): Deploy Docker images

#### Required GitHub Secrets

Configure these secrets in your GitHub repository:

```
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
SSH_PRIVATE_KEY=your-ssh-public-key
```

#### Workflow Triggers

- **Push to main/develop**: Automatic deployment

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd jelou_test
   ```

2. **Set up environment variables**
   ```bash
   cp env.example .env
   # Edit .env with your database credentials
   ```

3. **Start with Docker Compose**
   ```bash
   docker-compose up -d
   ```

4. **Verify the application**
   ```bash
   curl http://INSTANCE_IP/health
   ```

### AWS Deployment

1. **Configure Terraform variables**
   ```bash
   # Edit terraform.tfvars with your AWS settings
   ```

2. **Generate SSH key pair**
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/user-microservice-key
   ```

3. **Update terraform.tfvars**
   ```hcl
   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7... your-public-key-here"
   ```

4. **Deploy infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Access your application**
   ```bash
   # Get the public IP from Terraform output
   terraform output instance_public_ip
   
   # Test the application
   curl http://<PUBLIC_IP>/health
   ```

## API Endpoints

### Health Check
- `GET /health` - Application health status

### User Management
- `POST /users` - Create a new user
- `GET /users` - Get all users (with pagination)
- `GET /users/:id` - Get user by ID
- `PUT /users/:id` - Update user
- `DELETE /users/:id` - Delete user

### Example Usage

**Create a user:**
```bash
curl -X POST http://PUBLIC_IP/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com"}'
```

**Get all users:**
```bash
curl http://PUBLIC_IP/users?page=1&limit=10
```

## Docker Services

The application consists of three main services:

1. **postgres** - PostgreSQL 15 database
2. **user-service** - Node.js application
3. **nginx** - Reverse proxy

### Service Dependencies
- `user-service` depends on `postgres` (health check)
- `nginx` depends on `user-service`

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment | `development` |
| `PORT` | Application port | `3000` |
| `DB_HOST` | Database host | `localhost` |
| `DB_PORT` | Database port | `5432` |
| `DB_NAME` | Database name | `users_db` |
| `DB_USER` | Database user | `postgres` |
| `DB_PASSWORD` | Database password | `password` |

### Terraform Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `instance_type` | EC2 instance type | `t3.micro` |
| `environment` | Environment | `dev` |
| `db_password` | Database password | Required |
| `public_key` | SSH public key | Required |

## Monitoring

### Health Checks
- Application: `GET /health`
- Database connectivity included in health check
- Docker health checks for all services

## CI/CD Pipeline

### Automated Workflows

#### 1. Deploy Workflow (`docker-deploy.yml`)
- **Triggers**: Push to main/develop, PRs, manual dispatch
- **Features**:
  - Code quality checks (ESLint, security audit)
  - Docker build testing


#### 2. Docker Workflow (`terraform-infrastructure.yml`)
- **Triggers**: Push to main in the terraform folder or workflow file
- **Features**:
  - Terraform plan/apply
  - Health checks and API testing
  - Deployment summary with links

### Manual Deployment

You can trigger manual deployments using the GitHub Actions UI:

1. Go to Actions → Deploy User Management Microservice
2. Click "Run workflow"
3. Select the target environment
4. Click "Run workflow"

### Logs

**Docker Compose:**
```bash
docker-compose logs -f user-service
docker-compose logs -f postgres
```

**EC2 Instance:**
```bash
ssh -i ~/.ssh/user-microservice-key.pem ec2-user@<PUBLIC_IP>
sudo journalctl -u user-microservice -f
```