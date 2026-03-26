# Infrastructure as Code (IaC) - Deployment Guide

This directory contains Terraform and Ansible scripts to provision and deploy the application to AWS.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) >= 2.9
- AWS Account with appropriate permissions
- SSH key pair for EC2 access

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   VPC (10.0.0.0/16)                  │   │
│  │  ┌────────────────────────────────────────────────┐  │   │
│  │  │           Public Subnet (10.0.1.0/24)          │  │   │
│  │  │  ┌──────────────────────────────────────────┐  │  │   │
│  │  │  │         EC2 t3.micro                     │  │  │   │
│  │  │  │  ┌────────────────────────────────────┐  │  │  │   │
│  │  │  │  │  Docker Container                  │  │  │  │   │
│  │  │  │  │  ├── cicd-app (Node.js :3000)      │  │  │  │   │
│  │  │  │  │  ├── cicd-postgres (PostgreSQL)    │  │  │  │   │
│  │  │  │  │  └── cicd-redis (Redis)            │  │  │  │   │
│  │  │  │  └────────────────────────────────────┘  │  │  │   │
│  │  │  └──────────────────────────────────────────┘  │  │   │
│  │  └────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Terraform - Provision Infrastructure

### 1.1 Initialize Terraform

```bash
cd terraform
terraform init
```

### 1.2 Create a terraform.tfvars file

```bash
# terraform/terraform.tfvars
aws_region = "us-east-1"
environment = "prod"
ssh_public_key = "ssh-rsa AAAAB3NzaC1..."
instance_type = "t3.micro"
```

### 1.3 Plan and Apply

```bash
# Preview changes
terraform plan

# Apply changes (type "yes" to confirm)
terraform apply
```

### 1.4 Get Outputs

```bash
terraform output
```

Note the `ec2_public_ip` - you'll need it for Ansible inventory.

## Step 2: Ansible - Deploy Application

### 2.1 Update Inventory

Edit `ansible/inventory.ini` and replace `<EC2_PUBLIC_IP>` with the IP from Terraform output:

```ini
[app_servers]
app-server ansible_host=<YOUR_EC2_PUBLIC_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my-first-cicd-key.pem
```

### 2.2 Generate SSH Key (if needed)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/my-first-cicd-key.pem
chmod 400 ~/.ssh/my-first-cicd-key.pem
```

### 2.3 Add Public Key to AWS

Upload the public key to AWS EC2 Key Pairs or add it to the Terraform variable.

### 2.4 Run Ansible Playbook

```bash
cd ansible
ansible-playbook -i inventory.ini playbook.yml
```

## Step 3: Verify Deployment

After successful deployment, access the application:

- **App URL**: `http://<EC2_PUBLIC_IP>:3000`
- **Health Check**: `http://<EC2_PUBLIC_IP>:3000/api/health`
- **Users API**: `http://<EC2_PUBLIC_IP>:3000/api/users`

## Step 4: Cleanup

### Destroy Ansible (stop containers)
```bash
cd ansible
ansible-playbook -i inventory.ini playbook.yml --tags cleanup
```

### Destroy Terraform (remove infrastructure)
```bash
cd terraform
terraform destroy
```

## Security Notes

- The security group allows SSH (port 22) from anywhere - restrict in production
- Database credentials are in docker-compose.yml - use secrets in production
- Consider using AWS Secrets Manager or Parameter Store
- Enable SSL/TLS with AWS Certificate Manager for production

## Troubleshooting

### SSH Connection Issues
```bash
ssh -i ~/.ssh/my-first-cicd-key.pem ubuntu@<EC2_PUBLIC_IP>
```

### Check Docker Containers
```bash
docker exec -it cicd-app docker-compose ps
docker logs cicd-app
```

### Check Application Logs
```bash
docker exec -it cicd-app docker-compose logs app
```

## File Structure

```
my-first-cicd/
├── terraform/
│   ├── main.tf          # AWS resources
│   ├── variables.tf     # Variable definitions
│   └── outputs.tf       # Output values
├── ansible/
│   ├── inventory.ini    # Inventory file
│   ├── playbook.yml    # Main playbook
│   └── roles/
│       ├── docker/
│       │   └── tasks/main.yml
│       ├── docker-compose/
│       │   ├── tasks/main.yml
│       │   └── templates/docker-compose.yml.j2
│       └── app/
│           └── tasks/main.yml
└── README-IAC.md        # This file
```