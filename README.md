# Ron ZBD Challenge

This is a simple TypeScript application that exposes a few API endpoints using Express.js and provides Prometheus metrics, with complete AWS infrastructure deployment using Terraform.

## 🚀 Features

- **Health Check Endpoint**: Simple endpoint to verify the service is running
- **Prometheus Metrics**: Exportable metrics for monitoring and observability
- **Request Counter**: Tracks total HTTP requests with labels for method, route, and status code
- **Configurable Port**: Port can be configured via environment variable
- **AWS Infrastructure**: Complete deployment to 2 EC2 instances with Docker containerization
- **Security Hardening**: Enhanced security configurations and monitoring
- **CI/CD Pipeline**: Automated deployment with GitHub Actions

## 📡 API Endpoints

### `/health`

A health check endpoint that returns a `200 OK` response with JSON containing status, message, and request metadata.

**Example:**
```bash
curl http://127.0.0.1:8080/health
```

**Response:**
```json
{
  "statusCode": 200,
  "message": "I'm healthy",
  "metadata": {
    "timestamp": "2025-10-09T01:23:45.678Z",
    "ip": "::1",
    "userAgent": "curl/7.68.0",
    "method": "GET",
    "path": "/health",
    "protocol": "http",
    "hostname": "127.0.0.1"
  }
}
```

### `/metrics`

Exports metrics in Prometheus format. This endpoint can be used to scrape stats from the application for monitoring purposes.

**Example:**
```bash
curl http://127.0.0.1:8080/metrics
```

**Response:**
```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",route="/health",status_code="200",app="ron-zbd-challenge"} 1
...
```

### `/hello`

An endpoint that returns a "Hello, world!" message with JSON containing status, message, and request metadata. This is useful for demonstrating the metrics functionality and generating traffic.

**Example:**
```bash
curl http://127.0.0.1:8080/hello
```

**Response:**
```json
{
  "statusCode": 200,
  "message": "Hello, world!",
  "metadata": {
    "timestamp": "2025-10-09T01:23:45.678Z",
    "ip": "::1",
    "userAgent": "curl/7.68.0",
    "method": "GET",
    "path": "/hello",
    "protocol": "http",
    "hostname": "127.0.0.1"
  }
}
```

## ⚙️ Configuration

### Environment Variables

- **`PORT`**: The port on which the server will listen (default: `8080`)

### Examples

Run on default port (8080):
```bash
cd app
npm start
```

Run on custom port (3000):
```bash
cd app
PORT=3000 npm start
```

Run on custom port (9090):
```bash
cd app
PORT=9090 npm start
```

## 🚀 Quick Start Guide

### Prerequisites

- **AWS Account** with appropriate permissions
- **Terraform** installed (v1.0+)
- **Node.js** (v18 or later recommended)
- **npm** (comes with Node.js)
- **Docker** (for containerization)

### Deployment Flow

Follow these steps in order:

1. **🏗️ Deploy AWS Infrastructure** (Terraform)
2. **🔨 Build Application** (Docker)
3. **🚀 Deploy Application** to AWS instances
4. **📊 Monitor Application** (Prometheus + CloudWatch)

---

## 🏗️ Step 1: Deploy AWS Infrastructure

**Deploy the infrastructure first** before building the application.

### Quick Deploy

```bash
# Clone the repository
git clone https://github.com/your-username/ron-zbd-challenge.git
cd ron-zbd-challenge

# Deploy infrastructure
cd terraform
# Edit main.tf to update allowed_ssh_cidrs with your personal IP
./deploy.sh
```

**Important**: Before deploying, update the `allowed_ssh_cidrs` in `main.tf` with your personal IP address:
```hcl
allowed_ssh_cidrs = ["YOUR_IP_ADDRESS/32"]
```

This creates 2 EC2 instances ready for your application deployment.

---

## 🔨 Step 2: Build Application

After infrastructure is deployed, build your application.

### Local Development Setup

```bash
# Navigate to application directory
cd app

# Install dependencies
npm install

# Run locally for testing (optional)
npm start
```

The application will be running on `http://127.0.0.1:8080` by default.

---

## 🚀 Step 3: Deploy Application to AWS

After building your application, deploy it to the AWS infrastructure.

### Create Docker Image

```bash
# Create Dockerfile in app directory
cd app
cat > Dockerfile << EOF
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY src/ ./src/
EXPOSE 8080
CMD ["npm", "start"]
EOF

# Build Docker image
docker build -t ron-zbd-challenge-api .
```

### Deploy to Instance A (API Server)

```bash
# SSH to your API instance
ssh -i your-key.pem ec2-user@<instance-a-ip>

# Navigate to app directory
cd /opt/app

# Create docker-compose.yml
cat > docker-compose.yml << EOF
version: '3.8'
services:
  api:
    image: ron-zbd-challenge-api:latest
    ports:
      - "8080:8080"
    restart: unless-stopped
EOF

# Deploy application
docker-compose up -d

# Verify deployment
docker ps
curl http://localhost:8080/health
```

### Deploy Prometheus to Instance B

```bash
# SSH to your Prometheus instance
ssh -i your-key.pem ec2-user@<instance-b-ip>

# Navigate to app directory
cd /opt/app

# Create Prometheus configuration
cat > prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'api-server'
    static_configs:
      - targets: ['<instance-a-ip>:8080']
    metrics_path: '/metrics'
EOF

# Create docker-compose.yml
cat > docker-compose.yml << EOF
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    restart: unless-stopped
EOF

# Deploy Prometheus
docker-compose up -d

# Verify deployment
docker ps
curl http://localhost:9090
```

---

## 📊 Step 4: Monitor Application

Your application is now deployed and ready for monitoring.

### Access Monitoring Dashboards

- **API Health**: `http://<instance-a-ip>:8080/health`
- **API Metrics**: `http://<instance-a-ip>:8080/metrics`
- **Prometheus UI**: `http://<instance-b-ip>:9090`

### Test the Complete Setup

```bash
# Test API endpoints
curl http://<instance-a-ip>:8080/health
curl http://<instance-a-ip>:8080/hello
curl http://<instance-a-ip>:8080/metrics

# Check Prometheus targets
# Visit http://<instance-b-ip>:9090/targets
# Should show api-server target as UP
```

---

## 🏗️ Project Structure

```
ron-zbd-challenge/
├── app/                 # Application code
│   ├── src/
│   │   └── index.ts     # Main application file
│   ├── package.json     # Project dependencies and scripts
│   ├── package-lock.json # Lock file for dependencies
│   ├── tsconfig.json    # TypeScript configuration
│   └── node_modules/    # Node.js dependencies
├── terraform/           # Infrastructure as Code
│   ├── modules/         # Reusable Terraform modules
│   │   ├── vpc/         # VPC and networking
│   │   └── ec2/         # Single EC2 instance
│   ├── environments/    # Environment-specific configs
│   │   ├── dev/         # Development environment
│   │   └── prod/        # Production environment
│   ├── main.tf          # Root configuration
│   ├── backend.tf       # S3 backend configuration
│   └── test-security.sh # Security testing script
├── .github/workflows/   # CI/CD pipeline
└── README.md           # This file
```

## 📦 Dependencies

### Production Dependencies
- **express**: Fast, unopinionated web framework for Node.js
- **prom-client**: Prometheus client for Node.js

### Dev Dependencies
- **typescript**: TypeScript compiler
- **ts-node**: TypeScript execution environment for Node.js
- **@types/express**: TypeScript type definitions for Express
- **@types/node**: TypeScript type definitions for Node.js

## 📊 Metrics

The application exposes the following metrics:

- **`http_requests_total`**: Counter - Total number of HTTP requests
  - Labels:
    - `method`: HTTP method (e.g., GET, POST)
    - `route`: The endpoint path (e.g., /health, /metrics, /hello)
    - `status_code`: HTTP response status code (e.g., 200, 404)
    - `app`: Application name (ron-zbd-challenge)

### Using with Prometheus

To scrape metrics from this application with Prometheus, add the following to your `prometheus.yml` configuration:

```yaml
scrape_configs:
  - job_name: 'ron-zbd-challenge'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

## 🧪 Testing

First, make sure the application is running:
```bash
cd app
npm start
```

Then test all endpoints:
```bash
# Health check
curl http://127.0.0.1:8080/health

# Generate some traffic
curl http://127.0.0.1:8080/hello
curl http://127.0.0.1:8080/hello
curl http://127.0.0.1:8080/hello

# Check metrics
curl http://127.0.0.1:8080/metrics
```

---

## ☁️ Detailed AWS Infrastructure Guide

This section provides detailed information about the AWS infrastructure deployment.

### 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Infrastructure                       │
├─────────────────────────────────────────────────────────────┤
│  VPC (10.0.0.0/16)                                         │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   Instance A    │    │   Instance B    │                │
│  │  (API Server)   │    │  (Prometheus)   │                │
│  │                 │    │                 │                │
│  │ • Docker API    │    │ • Prometheus    │                │
│  │ • Port 8080     │    │ • Port 9090     │                │
│  │ • /metrics      │◄──►│ • Scraping      │                │
│  └─────────────────┘    └─────────────────┘                │
│                                                             │
│  Security Groups:                                           │
│  • SSH: Personal IP only                                   │
│  • API: Source security group for /metrics                 │
│  • Prometheus: Public access                               │
└─────────────────────────────────────────────────────────────┘
```

### 🔧 Deployment Options

#### Option 1: Manual Deployment (Root Directory)
```bash
cd terraform
# Edit main.tf to update allowed_ssh_cidrs with your personal IP
terraform init
terraform plan
terraform apply
```

#### Option 2: Environment-Specific Deployment
```bash
# Development Environment
cd terraform/environments/dev
# Edit main.tf to update allowed_ssh_cidrs with your personal IP
terraform init
terraform plan
terraform apply

# Production Environment
cd terraform/environments/prod
# Edit main.tf to update allowed_ssh_cidrs with your personal IP
terraform init
terraform plan
terraform apply
```

### 🏢 Environment-Specific Configuration

#### Development Environment
- **Instance Type**: t3.micro
- **Volume Size**: 20GB
- **VPC CIDR**: 10.0.0.0/16
- **Log Retention**: 14 days

#### Production Environment
- **Instance Type**: t3.small
- **Volume Size**: 50GB
- **VPC CIDR**: 10.1.0.0/16
- **Log Retention**: 30 days

### 🔒 Security Configuration

#### SSH Access
- **Restricted to personal IP only** (`${var.personal_ip}/32`)
- **No password authentication** - Key-based only
- **Connection limits** and timeout configured

#### Security Group Rules
- **Instance A (API Server)**:
  - SSH: Personal IP only
  - HTTP/HTTPS: Public access
  - Port 8080: Public access + Prometheus security group
  - **Metrics endpoint**: Only accessible from Prometheus instance

- **Instance B (Prometheus)**:
  - SSH: Personal IP only
  - HTTP/HTTPS: Public access
  - Port 9090: Public access (Prometheus UI)

#### Security Verification
Run the security test script:
```bash
cd terraform
./test-security.sh
```

### 🏗️ Modular Architecture

The infrastructure is organized into reusable modules:

```
terraform/
├── modules/
│   ├── vpc/                    # VPC and networking
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ec2/                    # Single EC2 instance (reusable)
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── user_data.sh
├── main.tf                     # Module instantiation with literal values
├── outputs.tf                  # Root outputs
└── deploy.sh                   # Deployment script
```

#### Module Benefits
- **🔧 Reusability**: Modules can be used across different environments
- **📦 Separation of Concerns**: VPC and EC2 logic separated
- **🔄 Maintainability**: Easier to update and modify individual components
- **🧪 Testability**: Each module can be tested independently
- **📚 Documentation**: Clear structure with focused responsibilities

### 📋 What Gets Created

- **2 EC2 t3.micro instances** (`instance-a` and `instance-b`) running **Amazon Linux 2023** (security-hardened)
- **VPC with public subnet** and security groups
- **CloudWatch logging** for centralized logs
- **Docker-ready infrastructure** for running any containerized application
- **Enhanced security hardening** including:
  - Firewall (firewalld) configuration
  - SSH hardening with key-only auth
  - Automatic security updates
  - Kernel security parameters
  - File system security
  - Docker and Docker Compose installed

### 🚪 Access Your Infrastructure

After deployment, SSH to your instances:

```bash
# SSH to instance (Amazon Linux 2023)
ssh -i your-key.pem ec2-user@<instance-ip>

# Check system status
/opt/app/monitor.sh

# Check Docker status
docker --version
docker-compose --version
systemctl status docker
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow
The CI/CD pipeline includes:

1. **Docker Image Build & Scan**:
   - Builds API Docker image
   - Pushes to Amazon ECR
   - Runs Trivy vulnerability scan
   - Uploads scan results to GitHub Security tab

2. **Infrastructure Setup**:
   - Creates S3 bucket for Terraform state
   - Creates DynamoDB table for state locking
   - Creates ECR repository

3. **Infrastructure Deployment**:
   - Terraform format check
   - Terraform validation
   - Terraform plan
   - Terraform apply (on main branch)

4. **API Deployment**:
   - Deploys API to Instance A using SSM
   - Verifies deployment health

### Required GitHub Secrets
```bash
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_ACCOUNT_ID=your_account_id
```

**Note**: Personal IP configuration is now done directly in the Terraform files, not via GitHub secrets.

## 📊 Monitoring Setup

### Prometheus Configuration
Instance B runs Prometheus to scrape metrics from Instance A:

```yaml
# Prometheus configuration (deployed via Docker)
scrape_configs:
  - job_name: 'api-server'
    static_configs:
      - targets: ['instance-a-ip:8080']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

### CloudWatch Integration
- **Log Groups**: `/aws/ec2/ron-zbd-challenge-{env}`
- **Log Streams**: Separate streams for each instance
- **Retention**: 14 days (dev), 30 days (prod)

### Testing Security Groups

#### Verify Prometheus Can Access API Metrics
```bash
# SSH to Prometheus instance
ssh -i your-key.pem ec2-user@<instance-b-ip>

# Test metrics access
curl -f http://<instance-a-ip>:8080/metrics
```

#### Test Security Group Misconfiguration
1. **Remove security group rule**:
   ```hcl
   # Comment out in terraform/environments/dev/main.tf
   # prometheus_security_group_id = module.instance_b.security_group_id
   ```

2. **Apply changes**:
   ```bash
   terraform apply
   ```

3. **Verify Prometheus cannot access metrics**:
   ```bash
   curl -f http://<instance-a-ip>:8080/metrics
   # Should fail with connection refused/timeout
   ```

---

## 🏗️ Terraform Modules

### VPC Module (`terraform/modules/vpc/`)

Creates the networking foundation:
- VPC with DNS support
- Internet Gateway
- Public subnet
- Route table and associations

**Usage:**
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  project_name         = "my-project"
  environment          = "prod"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  availability_zone   = "us-east-1a"
}
```

### EC2 Module (`terraform/modules/ec2/`)

Creates a single secure EC2 instance with:
- 1 EC2 instance (configurable name)
- Security groups with appropriate rules
- IAM roles and policies for CloudWatch
- CloudWatch log group
- Generic infrastructure setup (Docker, security hardening)

**Usage:**
```hcl
module "instance_a" {
  source = "./modules/ec2"
  
  project_name               = "my-project"
  environment                = "prod"
  vpc_id                    = module.vpc.vpc_id
  subnet_id                 = module.vpc.public_subnet_id
  ami_id                    = "ami-12345678"
  instance_name             = "instance-a"
  instance_type             = "t3.micro"
  allowed_ssh_cidrs         = ["10.0.0.0/8"]
  cloudwatch_log_group_name = "/aws/ec2/my-project"
}

# Create multiple instances by instantiating multiple times
module "instance_b" {
  source = "./modules/ec2"
  
  project_name               = "my-project"
  environment                = "prod"
  vpc_id                    = module.vpc.vpc_id
  subnet_id                 = module.vpc.public_subnet_id
  ami_id                    = "ami-12345678"
  instance_name             = "instance-b"
  instance_type             = "t3.micro"
  allowed_ssh_cidrs         = ["10.0.0.0/8"]
  cloudwatch_log_group_name = "/aws/ec2/my-project"
}
```

#### Module Structure
Each module follows the standard Terraform module structure:

```
module-name/
├── main.tf      # Main resource definitions
├── variables.tf # Input variables
├── outputs.tf   # Output values
└── README.md    # Module documentation (optional)
```

#### Module Benefits
- **Reusability**: Use modules across different environments
- **Maintainability**: Update modules independently
- **Testing**: Test modules in isolation
- **Documentation**: Clear interfaces with variables and outputs

## 🚨 Troubleshooting

### Common Issues

1. **SSH Access Denied**:
   - Verify your IP address in terraform.tfvars
   - Check security group rules
   - Ensure SSH key is correct

2. **Prometheus Cannot Scrape Metrics**:
   - Verify security group rules allow Prometheus to access API
   - Check if API is running on Instance A
   - Verify network connectivity between instances

3. **CI/CD Pipeline Fails**:
   - Check GitHub secrets are configured
   - Verify AWS credentials have sufficient permissions
   - Check ECR repository exists

### Useful Commands

```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids <security-group-id>

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/ron-zbd-challenge"

# Check instance status
aws ec2 describe-instances --instance-ids <instance-id>
```

## 🧹 Cleanup

```bash
terraform destroy
```

## 📋 Security Checklist

- ✅ SSH access restricted to personal IP
- ✅ Security groups use source security group rules for metrics access
- ✅ Automatic security updates enabled
- ✅ Firewall configured with minimal required ports
- ✅ CloudWatch logging enabled
- ✅ Container vulnerability scanning in CI/CD
- ✅ Terraform state encrypted in S3
- ✅ Environment separation (dev/prod)

## 🎯 Next Steps

1. **Configure your personal IP** in the main.tf files (replace `"0.0.0.0/0"` with `"YOUR_IP/32"`)
2. **Set up GitHub secrets** for CI/CD
3. **Deploy development environment**
4. **Test security group configuration**
5. **Deploy API and Prometheus applications**
6. **Verify monitoring is working**
7. **Deploy to production when ready**

## 📄 License

ISC