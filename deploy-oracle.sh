#!/bin/bash
# Oracle Cloud Free Tier Deployment Script
# This script deploys the CI/CD app to Oracle Cloud Always Free Tier

set -e

echo "=========================================="
echo "Oracle Cloud Free Tier Deployment"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Error: Terraform is not installed${NC}"
        echo "Install: https://www.terraform.io/downloads"
        exit 1
    fi
    
    if ! command -v ansible &> /dev/null; then
        echo -e "${RED}Error: Ansible is not installed${NC}"
        echo "Install: https://docs.ansible.com/ansible/latest/installation_guide"
        exit 1
    fi
    
    echo -e "${GREEN}All prerequisites installed!${NC}"
}

setup_oracle() {
    echo -e "${YELLOW}Setting up Oracle Cloud...${NC}"
    echo ""
    echo "Prerequisites:"
    echo "1. Go to https://cloud.oracle.com"
    echo "2. Sign up for Free Tier account"
    echo "3. Create API Key and get credentials"
    echo ""
    echo "Required values from OCI Console:"
    echo "- Tenancy OCID (from Profile > Tenancy)"
    echo "- User OCID (from Profile > User Settings)"
    echo "- API Key Fingerprint"
    echo "- Private Key path"
    echo ""
    
    read -p "Enter Tenancy OCID: " TENANCY_OCID
    read -p "Enter User OCID: " USER_OCID
    read -p "Enter API Key Fingerprint: " FINGERPRINT
    read -p "Enter Private Key path [~/.oci/oci_api_key.pem]: " PRIVATE_KEY_PATH
    
    PRIVATE_KEY_PATH=${PRIVATE_KEY_PATH:-~/.oci/oci_api_key.pem}
    
    # Update terraform variables
    cat > terraform-oracle/terraform.tfvars << EOF
tenancy_ocid = "$TENANCY_OCID"
user_ocid = "$USER_OCID"
fingerprint = "$FINGERPRINT"
private_key_path = "$PRIVATE_KEY_PATH"
region = "ap-tokyo-1"
EOF
    
    echo -e "${GREEN}Oracle Cloud configured!${NC}"
}

generate_ssh_key() {
    echo -e "${YELLOW}Generating SSH key...${NC}"
    
    SSH_KEY_PATH="$HOME/.ssh/my-first-cicd-oracle-key"
    
    if [ ! -f "$SSH_KEY_PATH" ]; then
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH"
        chmod 400 "$SSH_KEY_PATH"
        echo -e "${GREEN}SSH key generated at $SSH_KEY_PATH${NC}"
    else
        echo -e "${YELLOW}SSH key already exists${NC}"
    fi
    
    PUBLIC_KEY=$(cat "${SSH_KEY_PATH}.pub")
    
    # Add to terraform.tfvars
    echo "ssh_public_key = \"$PUBLIC_KEY\"" >> terraform-oracle/terraform.tfvars
}

deploy_infrastructure() {
    echo -e "${YELLOW}Deploying Oracle Cloud infrastructure...${NC}"
    
    cd terraform-oracle
    terraform init
    terraform plan
    terraform apply
    
    INSTANCE_IP=$(terraform output -raw instance_ip)
    cd ..
    
    echo -e "${GREEN}Infrastructure deployed!${NC}"
    echo "Instance IP: $INSTANCE_IP"
}

update_inventory() {
    INSTANCE_IP=$1
    
    sed -i "s/<ORACLE_INSTANCE_IP>/$INSTANCE_IP/" ansible-oracle/inventory.ini
    
    echo -e "${GREEN}Inventory updated!${NC}"
}

deploy_application() {
    echo -e "${YELLOW}Deploying application with Ansible...${NC}"
    
    cd ansible-oracle
    ansible-playbook -i inventory.ini playbook.yml
    cd ..
    
    echo -e "${GREEN}Application deployed!${NC}"
}

main() {
    check_prerequisites
    
    echo "Starting deployment to Oracle Cloud Free Tier..."
    echo ""
    
    # Setup Oracle Cloud
    read -p "Configure Oracle Cloud credentials? (y/n): " SETUP_ORACLE
    if [ "$SETUP_ORACLE" = "y" ]; then
        setup_oracle
    fi
    
    # Generate SSH key
    generate_ssh_key
    
    # Deploy infrastructure
    read -p "Deploy Oracle Cloud infrastructure? (y/n): " DEPLOY_INFRA
    if [ "$DEPLOY_INFRA" = "y" ]; then
        deploy_infrastructure
        INSTANCE_IP=$(cd terraform-oracle && terraform output -raw instance_ip)
    else
        echo -e "${YELLOW}Enter instance IP:${NC}"
        read INSTANCE_IP
    fi
    
    # Update inventory
    update_inventory $INSTANCE_IP
    
    # Deploy application
    read -p "Deploy application? (y/n): " DEPLOY_APP
    if [ "$DEPLOY_APP" = "y" ]; then
        deploy_application
    fi
    
    echo ""
    echo -e "${GREEN}=========================================="
    echo "Deployment Complete!"
    echo "App URL: http://$INSTANCE_IP:3000"
    echo "Health Check: http://$INSTANCE_IP:3000/api/health"
    echo "==========================================${NC}"
}

main "$@"