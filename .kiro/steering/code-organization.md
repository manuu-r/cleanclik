# Code Organization Guidelines

## File Placement Rules

### Services Directory (`lib/core/services/`)
- **ONLY** production service classes should be placed here
- **NO** test files, example files, or demo code
- Services should be focused, single-responsibility classes
- Each service should have proper error handling and resource disposal

### Test Files
- Unit tests belong in `test/` directory with `_test.dart` suffix
- Widget tests belong in `test/widget/` directory
- Integration tests belong in `test/integration/` directory
- **NEVER** place test files in production code directories

### Example/Demo Code
- Example code should go in `example/` directory at project root
- Demo implementations should be in separate demo projects
- Proof-of-concept code should be in `poc/` or similar directory
- **NEVER** mix example code with production services

### Models Directory (`lib/core/models/`)
- Data classes and entities only
- No business logic or service implementations
- Pure data structures with serialization/deserialization

### Providers Directory (`lib/core/providers/`)
- Riverpod providers only
- State management configuration
- Provider composition and dependencies

## Naming Conventions

### Services
- End with `Service` suffix (e.g., `ObjectTrackingService`)
- Use descriptive, action-oriented names
- Avoid generic names like `Helper` or `Util`

### Models
- Use noun-based names (e.g., `DetectedObject`, `UserInventory`)
- Avoid `Model` suffix unless necessary for disambiguation
- Use clear, domain-specific terminology

### Files
- Use `snake_case.dart` for all Dart files
- Match class name with file name in snake_case
- Be descriptive and avoid abbreviations

## Architecture Principles

### Separation of Concerns
- Services handle business logic and external integrations
- Models represent data structures
- Providers manage state and dependencies
- UI components focus on presentation only

### Dependencies
- Services can depend on other services via constructor injection
- Models should be dependency-free data structures
- Providers orchestrate service dependencies
- Avoid circular dependencies

### Error Handling
- All services must implement proper error handling
- Use specific exception types for different error conditions
- Log errors appropriately for debugging
- Provide graceful fallbacks where possible

### Resource Management
- All services with resources (streams, timers, etc.) must implement `dispose()`
- Use proper lifecycle management for StreamControllers
- Cancel subscriptions and timers in dispose methods
- Prevent memory leaks through proper cleanup