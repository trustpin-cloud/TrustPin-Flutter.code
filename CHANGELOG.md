# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-08-14

### Updated

- **iOS**: Updated SDK
- **macOS**: Updated SDK
- **Android**: Updated SDK
- **Documentation**: Updated documentation and examples


## [1.0.0] - 2025-08-05

### Added

#### Core Features
- Initial release of TrustPin Flutter SDK
- SSL certificate pinning with SHA-256/SHA-512 public key pins
- JWS-based configuration fetching from TrustPin CDN
- Support for strict and permissive pinning modes
- Comprehensive error handling with detailed error types
- Configurable logging levels (none, error, info, debug)

#### Platform Support
- **iOS**: Native implementation using TrustPin Swift SDK
  - Minimum iOS 13.0+
  - Swift 5.0+ compatibility
  - Async/await support
- **Android**: Native implementation using TrustPin Kotlin SDK
  - Minimum API 21 (Android 5.0)+
  - Kotlin coroutines support
- **macOS**: Native implementation using TrustPin Swift SDK
  - Minimum macOS 13.0+
  - Sandboxing support with proper entitlements

#### API
- `TrustPinSDK.setup()` - Initialize SDK with organization credentials
- `TrustPinSDK.verify()` - Verify certificate against configured pins
- `TrustPinSDK.setLogLevel()` - Configure logging verbosity
- `TrustPinException` - Comprehensive error handling
- `TrustPinMode` enum - Strict/permissive pinning modes
- `TrustPinLogLevel` enum - Logging level configuration

#### Documentation
- Comprehensive README with usage examples
- API reference documentation
- Platform-specific setup guides
- Security best practices
- Migration guide from native SDKs
- Example applications with complete implementations

#### Testing
- Unit tests for all public APIs
- Integration tests with mock platform
- Method channel tests
- Platform interface tests
- Error handling test coverage

#### Development Tools
- GitHub Actions CI/CD pipeline
- Automated testing on multiple platforms
- Code quality checks with dart analyze
- Formatting validation
- Comprehensive test suite

### Dependencies
- Flutter SDK: 3.3.0+
- Dart SDK: 3.8.1+
- iOS: TrustPinKit 1.0.0
- Android: TrustPin Kotlin SDK 1.0.0

### Security
- Cryptographic validation of configuration integrity
- ECDSA P-256 signature verification
- Secure credential handling
- Thread-safe implementation
- Network security best practices
