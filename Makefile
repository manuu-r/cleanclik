# CleanClik Test Makefile
# Provides convenient commands for running tests and coverage analysis

.PHONY: help test test-unit test-widget test-integration test-golden test-performance coverage coverage-html clean setup

# Default target
help:
	@echo "CleanClik Test Commands"
	@echo "======================"
	@echo ""
	@echo "Setup:"
	@echo "  setup           - Install dependencies and generate code"
	@echo "  clean           - Clean build artifacts and coverage data"
	@echo ""
	@echo "Testing:"
	@echo "  test            - Run all tests"
	@echo "  test-unit       - Run unit tests only"
	@echo "  test-widget     - Run widget tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  test-golden     - Run golden tests only"
	@echo "  test-performance - Run performance tests only"
	@echo ""
	@echo "Coverage:"
	@echo "  coverage        - Generate test coverage report"
	@echo "  coverage-html   - Generate HTML coverage report"
	@echo "  coverage-analyze - Run detailed coverage analysis"
	@echo ""
	@echo "Quality:"
	@echo "  analyze         - Run Flutter analyzer"
	@echo "  format          - Format Dart code"
	@echo "  check           - Run all quality checks"

# Setup commands
setup:
	@echo "🔧 Setting up CleanClik test environment..."
	flutter pub get
	dart run build_runner build --delete-conflicting-outputs
	@echo "✅ Setup complete!"

clean:
	@echo "🧹 Cleaning build artifacts..."
	flutter clean
	rm -rf coverage/
	rm -rf build/
	rm -rf .dart_tool/build/
	@echo "✅ Clean complete!"

# Test commands
test: setup
	@echo "🧪 Running all CleanClik tests..."
	flutter test --exclude-tags=performance

test-unit: setup
	@echo "🔬 Running unit tests..."
	flutter test --tags=unit test/unit/

test-widget: setup
	@echo "🎨 Running widget tests..."
	flutter test --tags=widget test/widget/

test-integration: setup
	@echo "🔄 Running integration tests..."
	flutter test --tags=integration test/integration/

test-golden: setup
	@echo "✨ Running golden tests..."
	flutter test --tags=golden test/golden/

test-performance: setup
	@echo "⚡ Running performance tests..."
	flutter test --tags=performance test/performance/

# Coverage commands
coverage: setup
	@echo "📊 Generating test coverage..."
	./scripts/test_coverage.sh

coverage-html: coverage
	@echo "📄 Opening HTML coverage report..."
	@if [ -f coverage/html/index.html ]; then \
		open coverage/html/index.html || xdg-open coverage/html/index.html || echo "Please open coverage/html/index.html manually"; \
	else \
		echo "❌ HTML coverage report not found. Run 'make coverage' first."; \
	fi

coverage-analyze: coverage
	@echo "🔍 Running detailed coverage analysis..."
	dart run scripts/coverage_analysis.dart

# Quality commands
analyze: setup
	@echo "🔍 Running Flutter analyzer..."
	flutter analyze

format:
	@echo "🎨 Formatting Dart code..."
	dart format .

check: analyze format test
	@echo "✅ All quality checks passed!"

# Development helpers
watch-unit:
	@echo "👀 Watching unit tests..."
	find test/unit lib -name "*.dart" | entr -r make test-unit

watch-widget:
	@echo "👀 Watching widget tests..."
	find test/widget lib -name "*.dart" | entr -r make test-widget

# CI/CD helpers
ci-test: setup
	@echo "🤖 Running CI test suite..."
	flutter analyze
	flutter test --coverage --exclude-tags=integration,golden
	./scripts/coverage_analysis.dart

ci-integration: setup
	@echo "🤖 Running CI integration tests..."
	flutter test --tags=integration test/integration/

ci-golden: setup
	@echo "🤖 Running CI golden tests..."
	flutter test --tags=golden test/golden/

# Update golden files
update-goldens: setup
	@echo "🖼️ Updating golden files..."
	flutter test --update-goldens --tags=golden test/golden/

# Generate test reports
report:
	@echo "📋 Generating test reports..."
	@mkdir -p reports
	flutter test --machine > reports/test_results.json
	@echo "Test results saved to reports/test_results.json"

# Riverpod code generation
generate:
	@echo "🔧 Generating Riverpod code..."
	dart run build_runner build --delete-conflicting-outputs

watch-generate:
	@echo "👀 Watching for Riverpod code changes..."
	dart run build_runner watch --delete-conflicting-outputs