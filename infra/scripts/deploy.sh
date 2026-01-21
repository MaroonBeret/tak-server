#!/bin/bash
# TAK Server Production Deployment Script
# This script helps deploy the TAK server with Caddy reverse proxy to production

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== TAK Server Production Deployment ===${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.prod.yml" ]; then
    echo -e "${RED}Error: Must run from the infra/ directory${NC}"
    exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠ .env file not found. Creating from .env.example...${NC}"
    cp .env.example .env
    echo -e "${RED}⚠ IMPORTANT: Edit .env and set secure values before deploying!${NC}"
    echo ""
    read -p "Press Enter to edit .env now, or Ctrl+C to exit..."
    ${EDITOR:-nano} .env
fi

# Source the .env file
set -a
source .env
set +a

echo -e "${BLUE}Configuration:${NC}"
echo "  Domain: $TAK_DOMAIN"
echo "  Admin Email: $ADMIN_EMAIL"
echo ""

# Pre-flight checks
echo -e "${BLUE}Pre-flight checks:${NC}"

# Check DNS
echo -n "  Checking DNS for $TAK_DOMAIN... "
if dig +short "$TAK_DOMAIN" > /dev/null 2>&1; then
    IP=$(dig +short "$TAK_DOMAIN" | tail -1)
    echo -e "${GREEN}✓ Resolves to $IP${NC}"
else
    echo -e "${YELLOW}⚠ DNS not configured or not propagated${NC}"
    read -p "  Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check Docker
echo -n "  Checking Docker... "
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${RED}✗ Docker not found${NC}"
    exit 1
fi

# Check Docker Compose
echo -n "  Checking Docker Compose... "
if docker compose version &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${RED}✗ Docker Compose not found${NC}"
    exit 1
fi

echo ""

# Deployment options
echo -e "${BLUE}Deployment options:${NC}"
echo "  1. Build and start (fresh deployment)"
echo "  2. Pull and restart (update)"
echo "  3. Stop services"
echo "  4. View logs"
echo "  5. Status"
echo ""
read -p "Select option (1-5): " -n 1 -r
echo

case $REPLY in
    1)
        echo -e "${YELLOW}Building and starting services...${NC}"
        docker compose -f docker-compose.prod.yml build
        docker compose -f docker-compose.prod.yml up -d
        echo -e "${GREEN}✓ Services started${NC}"
        ;;
    2)
        echo -e "${YELLOW}Updating services...${NC}"
        docker compose -f docker-compose.prod.yml pull
        docker compose -f docker-compose.prod.yml up -d
        echo -e "${GREEN}✓ Services updated${NC}"
        ;;
    3)
        echo -e "${YELLOW}Stopping services...${NC}"
        docker compose -f docker-compose.prod.yml down
        echo -e "${GREEN}✓ Services stopped${NC}"
        ;;
    4)
        docker compose -f docker-compose.prod.yml logs -f
        ;;
    5)
        docker compose -f docker-compose.prod.yml ps
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Enable certificate enrollment in TAK admin UI:"
echo "     https://$TAK_DOMAIN/Marti/security/index.html#!/modifySecConfig"
echo ""
echo "  2. Generate test QR codes:"
echo "     cd ../customizations/scripts"
echo "     ./generate-qr.sh testuser"
echo ""
echo "  3. Monitor logs:"
echo "     docker compose -f docker-compose.prod.yml logs -f"
echo ""
