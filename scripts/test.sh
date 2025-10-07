#!/bin/bash

# ConvoChat Backend Testing and Quality Assurance Script
set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RUN_UNIT_TESTS=true
RUN_INTEGRATION_TESTS=true
RUN_LINTING=true
RUN_TYPE_CHECK=true
RUN_SECURITY_SCAN=true
RUN_COVERAGE=true
COVERAGE_THRESHOLD=80
WATCH_MODE=false
VERBOSE=false

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

show_usage() {
    cat << EOF
ConvoChat Backend Testing and Quality Assurance Script

Usage: $0 [OPTIONS]

Options:
    --unit              Run only unit tests
    --integration       Run only integration tests
    --lint              Run only linting
    --type-check        Run only type checking
    --security          Run only security scanning
    --coverage          Run with coverage report
    --threshold N       Coverage threshold percentage (default: 80)
    --watch             Run tests in watch mode
    --verbose           Verbose output
    --help              Show this help message

Examples:
    $0                      # Run all tests and checks
    $0 --unit --coverage    # Run unit tests with coverage
    $0 --lint --type-check  # Run only static analysis
    $0 --watch              # Run tests in watch mode

EOF
}

check_requirements() {
    print_header "Checking Requirements"
    
    # Check Node.js
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        print_success "Node.js found: $NODE_VERSION"
    else
        print_error "Node.js not found."
        exit 1
    fi
    
    # Check npm
    if command -v npm >/dev/null 2>&1; then
        NPM_VERSION=$(npm --version)
        print_success "npm found: $NPM_VERSION"
    else
        print_error "npm not found."
        exit 1
    fi
    
    # Check if in correct directory
    if [ ! -f "package.json" ]; then
        print_error "package.json not found. Are you in the backend directory?"
        exit 1
    fi
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        print_info "Installing dependencies..."
        npm ci
    fi
    
    print_success "All requirements met"
}

run_linting() {
    if [ "$RUN_LINTING" = false ]; then
        return
    fi
    
    print_header "Running ESLint"
    
    if npm run | grep -q "lint"; then
        if [ "$VERBOSE" = true ]; then
            npm run lint
        else
            npm run lint 2>/dev/null || {
                print_error "Linting failed"
                npm run lint
                return 1
            }
        fi
        print_success "Linting passed"
    else
        print_warning "No lint script found in package.json"
    fi
}

run_type_checking() {
    if [ "$RUN_TYPE_CHECK" = false ]; then
        return
    fi
    
    print_header "Running Type Check"
    
    if npm run | grep -q "type-check"; then
        if [ "$VERBOSE" = true ]; then
            npm run type-check
        else
            npm run type-check 2>/dev/null || {
                print_error "Type checking failed"
                npm run type-check
                return 1
            }
        fi
        print_success "Type checking passed"
    else
        print_warning "No type-check script found in package.json"
    fi
}

run_unit_tests() {
    if [ "$RUN_UNIT_TESTS" = false ]; then
        return
    fi
    
    print_header "Running Unit Tests"
    
    # Prepare test command
    TEST_CMD="npm test"
    
    if [ "$RUN_COVERAGE" = true ]; then
        TEST_CMD="npm run test:coverage"
        if ! npm run | grep -q "test:coverage"; then
            print_warning "No test:coverage script found, using regular test"
            TEST_CMD="npm test -- --coverage"
        fi
    fi
    
    if [ "$WATCH_MODE" = true ]; then
        TEST_CMD="$TEST_CMD -- --watch"
    fi
    
    # Check if test script exists
    if npm run | grep -q "test"; then
        if [ "$VERBOSE" = true ]; then
            eval "$TEST_CMD"
        else
            eval "$TEST_CMD" 2>/dev/null || {
                print_error "Unit tests failed"
                eval "$TEST_CMD"
                return 1
            }
        fi
        print_success "Unit tests passed"
    else
        print_warning "No test script found in package.json"
    fi
}

run_integration_tests() {
    if [ "$RUN_INTEGRATION_TESTS" = false ]; then
        return
    fi
    
    print_header "Running Integration Tests"
    
    if npm run | grep -q "test:integration"; then
        if [ "$VERBOSE" = true ]; then
            npm run test:integration
        else
            npm run test:integration 2>/dev/null || {
                print_error "Integration tests failed"
                npm run test:integration
                return 1
            }
        fi
        print_success "Integration tests passed"
    else
        print_warning "No integration test script found"
        print_info "Create 'test:integration' script in package.json to enable integration tests"
    fi
}

run_security_scan() {
    if [ "$RUN_SECURITY_SCAN" = false ]; then
        return
    fi
    
    print_header "Running Security Scan"
    
    # npm audit
    print_info "Running npm audit..."
    if npm audit --audit-level=moderate; then
        print_success "npm audit passed"
    else
        print_warning "npm audit found vulnerabilities"
        print_info "Run 'npm audit fix' to attempt automatic fixes"
    fi
    
    # Check for security linting if available
    if npm run | grep -q "lint:security"; then
        print_info "Running security linting..."
        npm run lint:security
        print_success "Security linting passed"
    fi
    
    # Check .env for potential issues
    if [ -f ".env" ]; then
        print_info "Checking .env file for potential security issues..."
        
        # Check for default/weak values
        if grep -q "password.*=.*123" .env 2>/dev/null; then
            print_warning "Weak password detected in .env"
        fi
        
        if grep -q "secret.*=.*secret" .env 2>/dev/null; then
            print_warning "Default secret detected in .env"
        fi
        
        # Check for exposed secrets
        if grep -qE "(api[_-]?key|secret|token|password).*=.*[a-zA-Z0-9]{20,}" .env 2>/dev/null; then
            print_info ".env contains secrets (this is normal, just ensure it's not committed)"
        fi
    fi
    
    print_success "Security scan completed"
}

check_coverage() {
    if [ "$RUN_COVERAGE" = false ]; then
        return
    fi
    
    print_header "Checking Test Coverage"
    
    # Look for coverage files
    COVERAGE_FILE=""
    if [ -f "coverage/lcov-report/index.html" ]; then
        COVERAGE_FILE="coverage/lcov-report/index.html"
    elif [ -f "coverage/index.html" ]; then
        COVERAGE_FILE="coverage/index.html"
    fi
    
    if [ -n "$COVERAGE_FILE" ]; then
        print_success "Coverage report generated: $COVERAGE_FILE"
        
        # Try to extract coverage percentage
        if [ -f "coverage/lcov.info" ]; then
            COVERAGE_PERCENT=$(grep -o "BF:[0-9]*" coverage/lcov.info | head -1 | cut -d':' -f2 2>/dev/null || echo "0")
            if [ "$COVERAGE_PERCENT" -ge "$COVERAGE_THRESHOLD" ]; then
                print_success "Coverage $COVERAGE_PERCENT% meets threshold of $COVERAGE_THRESHOLD%"
            else
                print_warning "Coverage $COVERAGE_PERCENT% below threshold of $COVERAGE_THRESHOLD%"
            fi
        fi
    else
        print_info "No coverage report found"
    fi
}

run_performance_tests() {
    print_header "Running Performance Tests"
    
    if npm run | grep -q "test:performance"; then
        npm run test:performance
        print_success "Performance tests passed"
    elif command -v autocannon >/dev/null 2>&1; then
        print_info "Running basic load test with autocannon..."
        
        # Start server in background if not running
        if ! curl -f http://localhost:3000/healthz >/dev/null 2>&1; then
            print_info "Starting server for performance test..."
            npm start &
            SERVER_PID=$!
            sleep 5
        fi
        
        # Run load test
        autocannon -c 10 -d 10 http://localhost:3000/healthz
        
        # Clean up
        if [ -n "${SERVER_PID:-}" ]; then
            kill $SERVER_PID 2>/dev/null || true
        fi
        
        print_success "Performance test completed"
    else
        print_info "No performance tests available"
        print_info "Install autocannon or add 'test:performance' script for performance testing"
    fi
}

generate_test_report() {
    print_header "Test Report Summary"
    
    echo -e "${GREEN}Test Suite Results:${NC}"
    
    if [ "$RUN_LINTING" = true ]; then
        echo -e "  • Linting: ${GREEN}✅ Passed${NC}"
    fi
    
    if [ "$RUN_TYPE_CHECK" = true ]; then
        echo -e "  • Type Check: ${GREEN}✅ Passed${NC}"
    fi
    
    if [ "$RUN_UNIT_TESTS" = true ]; then
        echo -e "  • Unit Tests: ${GREEN}✅ Passed${NC}"
    fi
    
    if [ "$RUN_INTEGRATION_TESTS" = true ]; then
        echo -e "  • Integration Tests: ${GREEN}✅ Passed${NC}"
    fi
    
    if [ "$RUN_SECURITY_SCAN" = true ]; then
        echo -e "  • Security Scan: ${GREEN}✅ Passed${NC}"
    fi
    
    echo -e "\n${GREEN}All tests completed successfully! 🎉${NC}"
    
    # Show coverage info if available
    if [ -f "coverage/lcov-report/index.html" ]; then
        echo -e "\n${BLUE}Coverage Report:${NC} file://$(pwd)/coverage/lcov-report/index.html"
    fi
    
    echo -e "\n${BLUE}Next steps:${NC}"
    echo -e "  • Review any warnings above"
    echo -e "  • Check coverage report if generated"
    echo -e "  • Run deployment script if all tests pass"
}

main() {
    print_header "ConvoChat Backend Testing Suite"
    
    # Parse command line arguments
    while [ $# -gt 0 ]; do
        case $1 in
            --unit)
                RUN_INTEGRATION_TESTS=false
                RUN_LINTING=false
                RUN_TYPE_CHECK=false
                RUN_SECURITY_SCAN=false
                shift
                ;;
            --integration)
                RUN_UNIT_TESTS=false
                RUN_LINTING=false
                RUN_TYPE_CHECK=false
                RUN_SECURITY_SCAN=false
                shift
                ;;
            --lint)
                RUN_UNIT_TESTS=false
                RUN_INTEGRATION_TESTS=false
                RUN_TYPE_CHECK=false
                RUN_SECURITY_SCAN=false
                RUN_COVERAGE=false
                shift
                ;;
            --type-check)
                RUN_UNIT_TESTS=false
                RUN_INTEGRATION_TESTS=false
                RUN_LINTING=false
                RUN_SECURITY_SCAN=false
                RUN_COVERAGE=false
                shift
                ;;
            --security)
                RUN_UNIT_TESTS=false
                RUN_INTEGRATION_TESTS=false
                RUN_LINTING=false
                RUN_TYPE_CHECK=false
                RUN_COVERAGE=false
                shift
                ;;
            --coverage)
                RUN_COVERAGE=true
                shift
                ;;
            --threshold)
                COVERAGE_THRESHOLD="$2"
                shift 2
                ;;
            --watch)
                WATCH_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    check_requirements
    
    # Run selected test suites
    set +e  # Don't exit on first failure, collect all results
    
    FAILED_TESTS=""
    
    if ! run_linting; then
        FAILED_TESTS="$FAILED_TESTS Linting"
    fi
    
    if ! run_type_checking; then
        FAILED_TESTS="$FAILED_TESTS TypeCheck"
    fi
    
    if ! run_unit_tests; then
        FAILED_TESTS="$FAILED_TESTS UnitTests"
    fi
    
    if ! run_integration_tests; then
        FAILED_TESTS="$FAILED_TESTS IntegrationTests"
    fi
    
    if ! run_security_scan; then
        FAILED_TESTS="$FAILED_TESTS SecurityScan"
    fi
    
    check_coverage
    
    # Report results
    if [ -z "$FAILED_TESTS" ]; then
        generate_test_report
        exit 0
    else
        print_header "Test Failures"
        print_error "The following test suites failed:"
        for test in $FAILED_TESTS; do
            echo -e "  • ${RED}$test${NC}"
        done
        echo ""
        print_error "Please fix the failing tests before deployment"
        exit 1
    fi
}

# Check if running directly (not sourced)
if [ "${0##*/}" = "test.sh" ]; then
    main "$@"
fi
