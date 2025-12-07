#!/bin/bash

set -e

APP_URL="${APP_URL:-http://localhost:3000}"
MAX_RETRIES=30
RETRY_DELAY=2

echo "================================="
echo "Starting Smoke Tests"
echo "================================="
echo "Target URL: $APP_URL"
echo ""

wait_for_app() {
    echo "Waiting for application..."
    local count=0
    
    while [ $count -lt $MAX_RETRIES ]; do
        if curl -f -s "$APP_URL" > /dev/null 2>&1; then
            echo "Application is ready!"
            return 0
        fi
        
        count=$((count + 1))
        echo "Attempt $count/$MAX_RETRIES..."
        sleep $RETRY_DELAY
    done
    
    echo "Application failed to start"
    return 1
}

test_app_responds() {
    echo ""
    echo "Test 1: Application responds"
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "PASSED - HTTP Status: $HTTP_CODE"
        return 0
    else
        echo "FAILED - HTTP Status: $HTTP_CODE"
        return 1
    fi
}

test_html_content() {
    echo ""
    echo "Test 2: HTML content validation"
    
    RESPONSE=$(curl -s "$APP_URL")
    
    if echo "$RESPONSE" | grep -qi "calculator\|react\|root"; then
        echo "PASSED - Content found"
        return 0
    else
        echo "FAILED - Content not found"
        return 1
    fi
}

test_static_resources() {
    echo ""
    echo "Test 3: Static resources"
    
    RESPONSE=$(curl -s "$APP_URL")
    
    if echo "$RESPONSE" | grep -q "static/\|\.js\|\.css"; then
        echo "PASSED - Resources found"
        return 0
    else
        echo "FAILED - No resources"
        return 1
    fi
}

test_healthcheck() {
    echo ""
    echo "Test 4: Healthcheck endpoint"
    
    if curl -f -s "$APP_URL/health" > /dev/null 2>&1; then
        echo "PASSED - Healthcheck OK"
        return 0
    else
        echo "SKIPPED - No healthcheck"
        return 0
    fi
}

FAILED_TESTS=0

wait_for_app || exit 1

test_app_responds || FAILED_TESTS=$((FAILED_TESTS + 1))
test_html_content || FAILED_TESTS=$((FAILED_TESTS + 1))
test_static_resources || FAILED_TESTS=$((FAILED_TESTS + 1))
test_healthcheck || FAILED_TESTS=$((FAILED_TESTS + 1))

echo ""
echo "================================="
echo "Smoke Test Summary"
echo "================================="

if [ $FAILED_TESTS -eq 0 ]; then
    echo "All tests PASSED"
    exit 0
else
    echo "$FAILED_TESTS test(s) FAILED"
    exit 1
fi
