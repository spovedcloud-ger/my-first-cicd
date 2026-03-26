#!/bin/bash
# Oracle Cloud Free Tier Destroy Script

set -e

echo "=========================================="
echo "Oracle Cloud Free Tier Destroy Script"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

destroy_infrastructure() {
    echo -e "${YELLOW}Destroying Oracle Cloud infrastructure...${NC}"
    
    cd terraform-oracle
    terraform destroy
    cd ..
    
    echo -e "${GREEN}Infrastructure destroyed!${NC}"
}

main() {
    echo "Starting destruction of Oracle Cloud resources..."
    echo ""
    
    read -p "Destroy Oracle Cloud infrastructure? (y/n): " DESTROY_INFRA
    if [ "$DESTROY_INFRA" = "y" ]; then
        destroy_infrastructure
    fi
    
    echo ""
    echo -e "${GREEN}=========================================="
    echo "All resources destroyed!"
    echo "==========================================${NC}"
}

main "$@"