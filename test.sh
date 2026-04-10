#!/bin/bash

# Hospital Archive System - Automated Test Suite
set -e

COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${COLOR_BLUE}🧪 Hospital Photo Archive System - Test Suite${NC}"
echo "=================================================="
echo ""

PASS=0
FAIL=0

# Helper functions
test_endpoint() {
    local name=$1
    local method=$2
    local url=$3
    local expected_status=$4

    echo -n "Testing $name... "

    if [ "$method" = "GET" ]; then
        status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    else
        status=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$url")
    fi

    if [ "$status" = "$expected_status" ]; then
        echo -e "${COLOR_GREEN}✅ PASS${NC} (HTTP $status)"
        ((PASS++))
    else
        echo -e "${COLOR_RED}❌ FAIL${NC} (Expected $expected_status, got $status)"
        ((FAIL++))
    fi
}

test_container() {
    local container=$1
    echo -n "Checking $container... "

    if docker compose ps | grep -q "$container.*healthy\|Up"; then
        echo -e "${COLOR_GREEN}✅ Running${NC}"
        ((PASS++))
    elif docker compose ps | grep -q "$container.*Up"; then
        echo -e "${COLOR_YELLOW}⚠️ Up (not healthy yet)${NC}"
        ((PASS++))
    else
        echo -e "${COLOR_RED}❌ Not running${NC}"
        ((FAIL++))
    fi
}

# Test 1: Docker Services
echo -e "${COLOR_BLUE}Test 1: Docker Services${NC}"
echo "---"
test_container "immich-db"
test_container "immich-redis"
test_container "immich-server"
test_container "immich-microservices"
test_container "n8n"
test_container "barcode-service"
echo ""

# Test 2: API Endpoints
echo -e "${COLOR_BLUE}Test 2: API Health Checks${NC}"
echo "---"
test_endpoint "barcode-service /health" "GET" "http://localhost:5001/health" "200"
test_endpoint "immich-server ping" "POST" "http://localhost:2283/api/server/ping" "200"
test_endpoint "n8n health" "GET" "http://localhost:5678/healthz" "200"
echo ""

# Test 3: barcode-service Stats
echo -e "${COLOR_BLUE}Test 3: barcode-service Database${NC}"
echo "---"
echo -n "Checking database stats... "
STATS=$(curl -s http://localhost:5001/stats | jq '.stats')
if [ ! -z "$STATS" ]; then
    echo -e "${COLOR_GREEN}✅ Database OK${NC}"
    echo "  Total photos: $(echo $STATS | jq '.total_photos')"
    echo "  Barcodes: $(echo $STATS | jq '.barcodes')"
    echo "  Patient photos: $(echo $STATS | jq '.patient_photos')"
    ((PASS++))
else
    echo -e "${COLOR_RED}❌ Database error${NC}"
    ((FAIL++))
fi
echo ""

# Test 4: Photo Indexing
echo -e "${COLOR_BLUE}Test 4: Photo Indexing (Manual Test)${NC}"
echo "---"
echo -n "Sending test photo to index... "
RESPONSE=$(curl -s -X POST http://localhost:5001/photo/index \
  -H "Content-Type: application/json" \
  -d '{
    "immich_id": "test-photo-'$(date +%s)'",
    "taken_at": "2026-04-10T14:30:00Z"
  }')

if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    echo -e "${COLOR_GREEN}✅ Photo indexed${NC}"
    ((PASS++))
else
    echo -e "${COLOR_RED}❌ Photo indexing failed${NC}"
    ((FAIL++))
fi
echo ""

# Test 5: Time-Window Matching
echo -e "${COLOR_BLUE}Test 5: Time-Window Matching${NC}"
echo "---"
echo -n "Testing match endpoint... "
MATCHES=$(curl -s -X POST http://localhost:5001/match \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "2026-04-10T14:30:00Z",
    "patient_name": "Test Patient",
    "window_minutes": 30
  }')

if echo "$MATCHES" | jq -e '.matches' > /dev/null 2>&1; then
    echo -e "${COLOR_GREEN}✅ Matching working${NC}"
    COUNT=$(echo "$MATCHES" | jq '.count')
    echo "  Found $COUNT matches"
    ((PASS++))
else
    echo -e "${COLOR_RED}❌ Matching failed${NC}"
    ((FAIL++))
fi
echo ""

# Test 6: Immich API
echo -e "${COLOR_BLUE}Test 6: Immich API${NC}"
echo "---"

API_KEY=$(grep IMMICH_API_KEY .env 2>/dev/null | cut -d'=' -f2 || echo "not-set")

if [ "$API_KEY" = "not-set" ] || [ -z "$API_KEY" ]; then
    echo -e "${COLOR_YELLOW}⚠️ IMMICH_API_KEY not configured in .env${NC}"
    echo "   Get it from: http://localhost:2283 → Account Settings → API Keys"
else
    echo -n "Testing Immich API with key... "
    IMMICH_RESPONSE=$(curl -s -H "x-api-key: $API_KEY" \
      http://localhost:2283/api/server/ping)

    if echo "$IMMICH_RESPONSE" | jq -e '.res' > /dev/null 2>&1; then
        echo -e "${COLOR_GREEN}✅ API Key valid${NC}"
        ((PASS++))
    else
        echo -e "${COLOR_RED}❌ API Key invalid or expired${NC}"
        ((FAIL++))
    fi
fi
echo ""

# Test 7: File System
echo -e "${COLOR_BLUE}Test 7: File System${NC}"
echo "---"
test_archive_dir() {
    if [ -d "$1" ]; then
        echo -e "  ✅ $1 exists"
        ((PASS++))
    else
        echo -e "  ❌ $1 missing"
        ((FAIL++))
    fi
}

test_archive_dir "photos/immich"
test_archive_dir "photos/archive"
test_archive_dir "photos/unmatched"
test_archive_dir "photos/external"
echo ""

# Summary
echo -e "${COLOR_BLUE}════════════════════════════════════════${NC}"
echo -e "${COLOR_BLUE}Test Summary${NC}"
echo "---"
echo -e "Passed: ${COLOR_GREEN}$PASS${NC}"
echo -e "Failed: ${COLOR_RED}$FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${COLOR_GREEN}✅ All tests passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Import n8n workflows (01, 02, 03)"
    echo "2. Configure IMMICH_API_KEY in .env (if not done)"
    echo "3. Restart n8n: docker compose restart n8n"
    echo "4. Set up mobile device or test with sample images"
    exit 0
else
    echo -e "${COLOR_RED}❌ Some tests failed${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check logs: docker compose logs <service-name>"
    echo "2. Verify .env variables"
    echo "3. Make sure services have time to start (wait 30s)"
    exit 1
fi
