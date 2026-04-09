#!/bin/bash
set -euo pipefail

# E2E test runner for PiggyPulse iOS
# Usage: ./scripts/e2e-test.sh [--setup] [--teardown]
#
# Prerequisites:
#   - Docker (for the API backend)
#   - Xcode + iOS Simulator
#
# The script:
#   1. Starts the API backend via Docker Compose
#   2. Waits for the API to be healthy
#   3. Runs XCUITests against the Simulator
#   4. Stops the API backend

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

API_URL="http://127.0.0.1:18080"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.test.yaml"

start_api() {
    echo "Starting API backend..."
    docker-compose -f "$COMPOSE_FILE" up -d --wait

    echo "Waiting for API health..."
    for i in $(seq 1 60); do
        if curl -sf "$API_URL/v2/health" > /dev/null 2>&1; then
            echo "API ready after ${i}s"
            return 0
        fi
        sleep 1
    done
    echo "ERROR: API failed to start" >&2
    return 1
}

stop_api() {
    echo "Stopping API backend..."
    docker-compose -f "$COMPOSE_FILE" down -v
}

run_tests() {
    echo "Running XCUITests..."
    xcodebuild test \
        -project "$PROJECT_DIR/PiggyPulse.xcodeproj" \
        -scheme PiggyPulse \
        -testPlan E2E \
        -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
        -resultBundlePath "$PROJECT_DIR/test-results/e2e.xcresult" \
        E2E_API_URL="$API_URL/v2" \
        CODE_SIGNING_ALLOWED=NO \
        | xcbeautify 2>/dev/null || cat
}

# Handle arguments
case "${1:-run}" in
    --setup)
        start_api
        ;;
    --teardown)
        stop_api
        ;;
    *)
        start_api
        run_tests
        EXIT_CODE=$?
        stop_api
        exit $EXIT_CODE
        ;;
esac
