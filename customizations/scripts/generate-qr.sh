#!/bin/bash
# Generate QR codes for ATAK and iTAK enrollment
# Usage: ./generate-qr.sh [username] [password]
# If password is omitted, a random one will be generated

set -e

# Configuration
SERVER="${TAK_DOMAIN:-tak.karabastactical.nl}"
OUTPUT_DIR="${QR_OUTPUT_DIR:-./qr-codes}"

# Parse arguments
USERNAME="${1:-testuser}"
PASSWORD="${2:-$(openssl rand -hex 8)}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== AK as a Service - QR Code Generator ===${NC}"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create user in TAK if not exists
echo -e "${YELLOW}Creating user in TAK server...${NC}"
if docker exec tak-server-tak-1 java -jar /opt/tak/utils/UserManager.jar \
    usermod -A -p "$PASSWORD" "$USERNAME" 2>/dev/null; then
    echo -e "${GREEN}✓ User created/updated successfully${NC}"
else
    echo -e "${YELLOW}⚠ User may already exist (this is OK)${NC}"
fi

echo ""

# Check if qrencode is installed
if ! command -v qrencode &> /dev/null; then
    echo -e "${YELLOW}⚠ qrencode not found. Install with: brew install qrencode (macOS) or apt install qrencode (Linux)${NC}"
    echo "Generating URIs only (no QR images)..."
    GENERATE_IMAGES=false
else
    GENERATE_IMAGES=true
fi

echo ""

# ATAK QR (tak:// URI)
ATAK_URI="tak://enroll?host=${SERVER}&port=443&username=${USERNAME}&password=${PASSWORD}&name=KarabasTAK"
echo -e "${BLUE}ATAK URI:${NC}"
echo "$ATAK_URI"

if [ "$GENERATE_IMAGES" = true ]; then
    qrencode -o "${OUTPUT_DIR}/qr-atak-${USERNAME}.png" "$ATAK_URI"
    echo -e "${GREEN}✓ Generated: ${OUTPUT_DIR}/qr-atak-${USERNAME}.png${NC}"
fi

echo ""

# iTAK QR (simple format)
ITAK_STRING="KarabasTAK,${SERVER},8089,SSL"
echo -e "${BLUE}iTAK String:${NC}"
echo "$ITAK_STRING"

if [ "$GENERATE_IMAGES" = true ]; then
    qrencode -o "${OUTPUT_DIR}/qr-itak-${USERNAME}.png" "$ITAK_STRING"
    echo -e "${GREEN}✓ Generated: ${OUTPUT_DIR}/qr-itak-${USERNAME}.png${NC}"
fi

echo ""
echo -e "${GREEN}=== Credentials ===${NC}"
echo "  Username: $USERNAME"
echo "  Password: $PASSWORD"
echo ""
echo -e "${YELLOW}Note: iTAK users will need to enter these credentials after scanning.${NC}"
echo ""
echo -e "${GREEN}=== Next Steps ===${NC}"
echo "1. ATAK users: Scan qr-atak-${USERNAME}.png with your device camera"
echo "2. iTAK users: Scan qr-itak-${USERNAME}.png, then enter credentials when prompted"
echo "3. Test connection by checking the map for server connectivity indicator"
echo ""
