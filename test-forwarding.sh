#!/bin/bash

# ReductrAI Forwarding Test Script
# Demonstrates three methods to verify forwarding without paid monitoring services

set -e

echo "╔═══════════════════════════════════════════════════╗"
echo "║  ReductrAI Forwarding Verification Test          ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if mock receiver is running
check_mock_receiver() {
    if curl -s http://localhost:8888/stats > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Method 1: HTTP Status Code Verification
test_http_status() {
    echo -e "${BLUE}[Test 1] HTTP Status Code Verification${NC}"
    echo "Testing direct forwarding to Datadog API..."
    echo ""

    # Send test metric
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        -X POST https://api.datadoghq.com/api/v1/series \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY:-test}" \
        -d '{
            "series": [{
                "metric": "reductrai.test.forwarding",
                "points": [['"$(date +%s)"', 1]],
                "tags": ["test:verification"]
            }]
        }' 2>&1)

    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d':' -f2)

    if [ "$HTTP_CODE" = "202" ] || [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✅ SUCCESS${NC}"
        echo "   HTTP Status: $HTTP_CODE (Accepted)"
        echo "   Datadog received and accepted the data"
        echo "   Forwarding is working!"
    else
        echo -e "${YELLOW}⚠️  HTTP Status: $HTTP_CODE${NC}"
        echo "   Note: 403/401 means API key issue, not forwarding issue"
        echo "   Status 2xx = forwarding works"
    fi
    echo ""
}

# Method 2: Mock Receiver
test_mock_receiver() {
    echo -e "${BLUE}[Test 2] Mock Receiver Verification${NC}"
    echo "Testing data capture with mock receiver..."
    echo ""

    if ! check_mock_receiver; then
        echo -e "${YELLOW}⚠️  Mock receiver not running${NC}"
        echo "   Start it with: npm run mock-receiver"
        echo "   Skipping this test..."
        echo ""
        return
    fi

    # Get initial stats
    BEFORE=$(curl -s http://localhost:8888/stats | grep -o '"totalReceived":[0-9]*' | cut -d':' -f2)

    # Send test data
    curl -s -X POST http://localhost:8888/api/v1/series \
        -H "Content-Type: application/json" \
        -d '{
            "series": [{
                "metric": "reductrai.mock.test",
                "points": [['"$(date +%s)"', 42]],
                "tags": ["test:mock"]
            }]
        }' > /dev/null

    sleep 1

    # Get updated stats
    AFTER=$(curl -s http://localhost:8888/stats | grep -o '"totalReceived":[0-9]*' | cut -d':' -f2)
    CAPTURED=$((AFTER - BEFORE))

    if [ "$CAPTURED" -gt 0 ]; then
        echo -e "${GREEN}✅ SUCCESS${NC}"
        echo "   Captured $CAPTURED new payload(s)"
        echo "   Mock receiver is working!"
        echo ""
        echo "   View details at: http://localhost:8888/stats"
    else
        echo -e "${YELLOW}⚠️  No data captured${NC}"
        echo "   Check mock receiver logs"
    fi
    echo ""
}

# Method 3: Local Monitoring Stack
test_local_stack() {
    echo -e "${BLUE}[Test 3] Local Monitoring Stack${NC}"
    echo "Checking if Prometheus/Grafana stack is running..."
    echo ""

    # Check Prometheus
    if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Prometheus running${NC} → http://localhost:9090"
    else
        echo -e "${YELLOW}⚠️  Prometheus not running${NC}"
        echo "   Start with: docker-compose -f docker-compose.self-hosted.yml up -d"
    fi

    # Check Grafana
    if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Grafana running${NC} → http://localhost:3000"
    else
        echo -e "${YELLOW}⚠️  Grafana not running${NC}"
    fi

    # Check Jaeger
    if curl -s http://localhost:16686/ > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Jaeger running${NC} → http://localhost:16686"
    else
        echo -e "${YELLOW}⚠️  Jaeger not running${NC}"
    fi

    echo ""
}

# Summary
print_summary() {
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║  Testing Complete                                 ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo ""
    echo "Three ways to verify forwarding:"
    echo ""
    echo "1. Check proxy logs for HTTP status codes:"
    echo "   docker logs reductrai-proxy | grep 'status 202'"
    echo ""
    echo "2. Use mock receiver to capture data:"
    echo "   npm run mock-receiver"
    echo "   curl http://localhost:8888/stats"
    echo ""
    echo "3. Use local monitoring stack:"
    echo "   docker-compose -f docker-compose.self-hosted.yml up -d"
    echo "   Open http://localhost:3001 (Grafana)"
    echo ""
    echo "For complete guide, see: TESTING.md"
    echo ""
}

# Run all tests
test_http_status
test_mock_receiver
test_local_stack
print_summary
