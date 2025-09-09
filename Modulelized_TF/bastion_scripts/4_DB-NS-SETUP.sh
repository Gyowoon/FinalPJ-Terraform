#!/bin/bash
#set -euo pipefail

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Required environment variables check
required_vars=(
    "DB_MASTER_USERNAME"
    "DB_MASTER_PASSWORD"
    "RDS_ENDPOINT"
    "DB_NAME"
    "REDIS_ENDPOINT"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo -e "${RED}Error: Required variable $var is not set${NC}"
        exit 1
    fi
done

# Function to safely create namespace and service account
create_ns_sa() {
    echo -e "${GREEN}[1/3] Setting up namespace and service account...${NC}"

    if ! kubectl get ns shop >/dev/null 2>&1; then
        echo -e "${GREEN}Creating namespace: shop${NC}"
        kubectl create namespace shop
    fi

    if ! kubectl get serviceaccount shopping-mall-sa -n shop >/dev/null 2>&1; then
        echo -e "${GREEN}Creating service account: shopping-mall-sa${NC}"
        kubectl create serviceaccount shopping-mall-sa -n shop
    fi
}

# Function to create and validate secrets
create_secrets() {
    echo -e "${GREEN}[2/3] Creating secrets...${NC}"
    local db_uri="mysql+pymysql://${DB_MASTER_USERNAME}:${DB_MASTER_PASSWORD}@${RDS_ENDPOINT}:3306/${DB_NAME}?charset=utf8mb4"
    local redis_url="redis://${REDIS_ENDPOINT}:6379"
    
    # Generate JWT secret if not provided
    if [[ -z "${JWT_SECRET_KEY:-}" ]]; then
        JWT_SECRET_KEY=$(openssl rand -base64 32)
    fi

    # Validate connection strings
    if [[ ! "$db_uri" =~ ^mysql\+pymysql:// ]]; then
        echo -e "${RED}Error: Invalid DB_URI format${NC}"
        exit 1
    fi

    if [[ ! "$redis_url" =~ ^redis:// ]]; then
        echo -e "${RED}Error: Invalid REDIS_URL format${NC}"
        exit 1
    fi

    echo -e "${GREEN}Creating/updating shop-secrets...${NC}"
    kubectl delete secret shop-secrets -n shop >/dev/null 2>&1 || true
    
    if ! kubectl create secret generic shop-secrets -n shop \
        --from-literal=DB_URI="$db_uri" \
        --from-literal=REDIS_URL="$redis_url" \
        --from-literal=JWT_SECRET_KEY="$JWT_SECRET_KEY"; then
        echo -e "${RED}Failed to create secrets${NC}"
        exit 1
    fi

    echo -e "${GREEN}Secrets created successfully${NC}"
}

# Function to setup database
setup_database() {
    echo -e "${GREEN}[3/3] Setting up database...${NC}"
    
    # Check MySQL client
    if ! command -v mysql &>/dev/null; then
        echo -e "${YELLOW}Installing MySQL client...${NC}"
        sudo yum install -y mysql
    fi

    # Test connection
    if ! mysql -h "$RDS_ENDPOINT" -u "$DB_MASTER_USERNAME" -p"$DB_MASTER_PASSWORD" \
        -e "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${RED}Cannot connect to database${NC}"
        exit 1
    fi

    # Create database if not exists
    echo "Creating database if not exists..."
    mysql -h "$RDS_ENDPOINT" -u "$DB_MASTER_USERNAME" -p"$DB_MASTER_PASSWORD" \
        -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

    # Create tables using SQL file if exists
    SQL_FILE="./sql/init.sql"
    if [ -f "$SQL_FILE" ]; then
        echo "Initializing database schema..."
        mysql -h "$RDS_ENDPOINT" -u "$DB_MASTER_USERNAME" -p"$DB_MASTER_PASSWORD" \
            "$DB_NAME" < "$SQL_FILE"
    else
        echo -e "${YELLOW}Warning: $SQL_FILE not found, skipping schema initialization${NC}"
    fi
}

# Main execution
echo -e "${GREEN}Starting setup process...${NC}"

create_ns_sa
create_secrets
setup_database

echo -e "${GREEN}All resources created successfully${NC}"