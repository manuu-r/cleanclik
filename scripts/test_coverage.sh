#!/bin/bash

# CleanClik Test Coverage Script
# Runs tests with coverage collection and generates reports

set -e

echo "🧪 CleanClik Test Coverage Collection"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    exit 1
fi

# Clean previous coverage data
echo -e "${BLUE}🧹 Cleaning previous coverage data...${NC}"
rm -rf coverage/
mkdir -p coverage/

# Generate Riverpod code if needed
echo -e "${BLUE}🔧 Generating Riverpod code...${NC}"
dart run build_runner build --delete-conflicting-outputs

# Run unit tests with coverage
echo -e "${BLUE}🧪 Running unit tests with coverage...${NC}"
flutter test --coverage --exclude-tags=integration,golden test/unit/

# Run widget tests with coverage
echo -e "${BLUE}🎨 Running widget tests with coverage...${NC}"
flutter test --coverage --exclude-tags=integration,golden test/widget/

# Run integration tests (without coverage to avoid conflicts)
echo -e "${BLUE}🔄 Running integration tests...${NC}"
flutter test --exclude-tags=golden test/integration/

# Run golden tests (without coverage)
echo -e "${BLUE}✨ Running golden tests...${NC}"
flutter test --tags=golden test/golden/

# Generate coverage report
echo -e "${BLUE}📊 Generating coverage report...${NC}"

# Install lcov if not present (for HTML report generation)
if ! command -v genhtml &> /dev/null; then
    echo -e "${YELLOW}⚠️  lcov not found. Install with: brew install lcov (macOS) or apt-get install lcov (Ubuntu)${NC}"
fi

# Remove generated files from coverage
echo -e "${BLUE}🧹 Filtering out generated files from coverage...${NC}"
lcov --remove coverage/lcov.info \
    '**/*.g.dart' \
    '**/*.freezed.dart' \
    '**/generated_plugin_registrant.dart' \
    '**/firebase_options.dart' \
    'test/**' \
    --output-file coverage/lcov_filtered.info

# Generate HTML report
if command -v genhtml &> /dev/null; then
    echo -e "${BLUE}📄 Generating HTML coverage report...${NC}"
    genhtml coverage/lcov_filtered.info --output-directory coverage/html
    echo -e "${GREEN}✅ HTML coverage report generated at: coverage/html/index.html${NC}"
fi

# Calculate coverage percentages
echo -e "${BLUE}📈 Calculating coverage statistics...${NC}"

# Overall coverage
OVERALL_COVERAGE=$(lcov --summary coverage/lcov_filtered.info 2>/dev/null | grep "lines" | grep -o '[0-9.]*%' | head -1 | sed 's/%//')

# Service coverage (lib/core/services/)
lcov --extract coverage/lcov_filtered.info 'lib/core/services/*' --output-file coverage/services.info 2>/dev/null || true
SERVICE_COVERAGE=$(lcov --summary coverage/services.info 2>/dev/null | grep "lines" | grep -o '[0-9.]*%' | head -1 | sed 's/%//' || echo "0")

# Model coverage (lib/core/models/)
lcov --extract coverage/lcov_filtered.info 'lib/core/models/*' --output-file coverage/models.info 2>/dev/null || true
MODEL_COVERAGE=$(lcov --summary coverage/models.info 2>/dev/null | grep "lines" | grep -o '[0-9.]*%' | head -1 | sed 's/%//' || echo "0")

# Display results
echo ""
echo -e "${BLUE}📊 Coverage Summary${NC}"
echo "=================="
echo -e "Overall Coverage:  ${OVERALL_COVERAGE}%"
echo -e "Service Coverage:  ${SERVICE_COVERAGE}%"
echo -e "Model Coverage:    ${MODEL_COVERAGE}%"
echo ""

# Generate summary file for CI
mkdir -p coverage
cat > coverage/coverage_summary.txt << EOF
📊 **Coverage Summary**

| Category | Coverage | Threshold | Status |
|----------|----------|-----------|--------|
| Overall | ${OVERALL_COVERAGE}% | ${THRESHOLD_OVERALL}% | $([ $(echo "$OVERALL_COVERAGE >= $THRESHOLD_OVERALL" | bc -l) -eq 1 ] && echo "✅ Pass" || echo "❌ Fail") |
| Services | ${SERVICE_COVERAGE}% | ${THRESHOLD_SERVICES}% | $([ $(echo "$SERVICE_COVERAGE >= $THRESHOLD_SERVICES" | bc -l) -eq 1 ] && echo "✅ Pass" || echo "❌ Fail") |
| Models | ${MODEL_COVERAGE}% | ${THRESHOLD_MODELS}% | $([ $(echo "$MODEL_COVERAGE >= $THRESHOLD_MODELS" | bc -l) -eq 1 ] && echo "✅ Pass" || echo "❌ Fail") |

**Files Tested:** $(wc -l < coverage/lcov_filtered.info | awk '{print int($1/5)}') files
**Lines Covered:** ${OVERALL_COVERAGE}% (${totalHit}/${totalLines} lines)
EOF

# Set environment variables for CI
echo "COVERAGE_PERCENTAGE=${OVERALL_COVERAGE}" >> $GITHUB_ENV 2>/dev/null || true
if (( $(echo "$OVERALL_COVERAGE >= 90" | bc -l) )); then
    echo "COVERAGE_COLOR=brightgreen" >> $GITHUB_ENV 2>/dev/null || true
elif (( $(echo "$OVERALL_COVERAGE >= 80" | bc -l) )); then
    echo "COVERAGE_COLOR=yellow" >> $GITHUB_ENV 2>/dev/null || true
else
    echo "COVERAGE_COLOR=red" >> $GITHUB_ENV 2>/dev/null || true
fi

# Check thresholds
THRESHOLD_OVERALL=85
THRESHOLD_SERVICES=85
THRESHOLD_MODELS=95

PASS=true

if (( $(echo "$OVERALL_COVERAGE < $THRESHOLD_OVERALL" | bc -l) )); then
    echo -e "${RED}❌ Overall coverage ($OVERALL_COVERAGE%) below threshold ($THRESHOLD_OVERALL%)${NC}"
    PASS=false
else
    echo -e "${GREEN}✅ Overall coverage ($OVERALL_COVERAGE%) meets threshold ($THRESHOLD_OVERALL%)${NC}"
fi

if (( $(echo "$SERVICE_COVERAGE < $THRESHOLD_SERVICES" | bc -l) )); then
    echo -e "${RED}❌ Service coverage ($SERVICE_COVERAGE%) below threshold ($THRESHOLD_SERVICES%)${NC}"
    PASS=false
else
    echo -e "${GREEN}✅ Service coverage ($SERVICE_COVERAGE%) meets threshold ($THRESHOLD_SERVICES%)${NC}"
fi

if (( $(echo "$MODEL_COVERAGE < $THRESHOLD_MODELS" | bc -l) )); then
    echo -e "${RED}❌ Model coverage ($MODEL_COVERAGE%) below threshold ($THRESHOLD_MODELS%)${NC}"
    PASS=false
else
    echo -e "${GREEN}✅ Model coverage ($MODEL_COVERAGE%) meets threshold ($THRESHOLD_MODELS%)${NC}"
fi

echo ""
if [ "$PASS" = true ]; then
    echo -e "${GREEN}🎉 All coverage thresholds met!${NC}"
    exit 0
else
    echo -e "${RED}💥 Coverage thresholds not met. Please add more tests.${NC}"
    exit 1
fi