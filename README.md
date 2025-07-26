# TrustPin SDK for Flutter

[![pub package](https://img.shields.io/pub/v/trustpin_sdk.svg)](https://pub.dev/packages/trustpin_sdk)
[![documentation](https://img.shields.io/badge/documentation-GitHub%20Pages-blue)](https://trustpin-cloud.github.io/TrustPin-Flutter.code/)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![platform](https://img.shields.io/badge/platform-flutter-blue)](https://flutter.dev)

A comprehensive Flutter plugin for **[TrustPin](https://trustpin.cloud)** SSL certificate pinning that provides robust security against man-in-the-middle (MITM) attacks by validating server certificates against pre-configured public key pins.

> 🌐 **Get started at [TrustPin.cloud](https://trustpin.cloud)** | 🎯 **Manage your certificates in the [Cloud Console](https://app.trustpin.cloud)**

## 📋 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Platform Setup](#️-platform-setup)
- [Quick Start](#-quick-start)
- [Advanced Usage](#-advanced-usage)
- [API Documentation](https://trustpin-cloud.github.io/TrustPin-Flutter.code/trustpin_sdk/)
- [Example](#example)
- [Security Considerations](#security-considerations)
- [Platform-Specific Implementation](#platform-specific-implementation)
- [Security Best Practices](#-security-best-practices)
- [Performance Considerations](#-performance-considerations)
- [Testing](#-testing)
- [Example App](#-example-app)
- [Migration Guide](#-migration-guide)
- [Contributing](#-contributing)
- [License](#-license)
- [Support & Community](#-support--community)

## 🚀 Features

- **🔒 SSL Certificate Pinning**: Advanced certificate validation using SHA-256/SHA-512 public key pins
- **📋 JWS-based Configuration**: Securely fetch signed pinning configurations from TrustPin CDN
- **🌐 Cross-platform Support**: Native implementations for iOS (Swift), Android (Kotlin), and macOS (Swift)
- **⚙️ Flexible Pinning Modes**: Support for strict (production) and permissive (development) validation modes
- **🔧 Comprehensive Error Handling**: Detailed error types with programmatic checking capabilities
- **📊 Configurable Logging**: Multiple log levels for debugging, monitoring, and production use
- **🛡️ Thread Safety**: Built with Flutter's async/await pattern and native concurrency models
- **⚡ Intelligent Caching**: 10-minute configuration caching with stale fallback for performance
- **🔐 ECDSA P-256 Signature Verification**: Cryptographic validation of configuration integrity

## 📦 Installation

### Using pub.dev (Recommended)

Add TrustPin SDK to your `pubspec.yaml`:

```yaml
dependencies:
  trustpin_sdk: ^latest
```

Then install the package:

```bash
flutter pub get
```

### Using Git (Development)

For the latest development version:

```yaml
dependencies:
  trustpin_sdk:
    git:
      url: https://github.com/trustpin-cloud/trustpin-libraries.git
      path: flutter/trustpin_sdk
```

## 🛠️ Platform Setup

### iOS Requirements

- **Minimum iOS Version**: 13.0+
- **Xcode**: 15.0+
- **Swift**: 5.0+
- **Native Dependencies**: TrustPin Swift SDK (automatically configured)

The iOS implementation uses the native TrustPin Swift SDK which is automatically linked via CocoaPods. No additional configuration required.

### macOS Requirements

- **Minimum macOS Version**: 13.0+
- **Xcode**: 15.0+
- **Swift**: 5.0+
- **Native Dependencies**: TrustPin Swift SDK (automatically configured)

The macOS implementation uses the same native TrustPin Swift SDK as iOS, automatically linked via CocoaPods. Requires network client entitlement for sandbox apps.

### Android Requirements

- **Minimum SDK**: API 21 (Android 5.0)+
- **Target SDK**: API 34+ (recommended)
- **Kotlin**: 1.9.0+
- **Native Dependencies**: TrustPin Kotlin SDK (automatically configured)

The Android implementation uses the native TrustPin Kotlin SDK which is automatically included via Gradle. No additional configuration required.

### Network Permissions

The SDK requires network access to fetch pinning configurations. Ensure your app has proper network permissions:

#### Android
The plugin automatically includes the required network permission in its AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS
Network access is enabled by default. For apps targeting iOS 14+, ensure your Info.plist allows network access to `cdn.trustpin.cloud`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>cdn.trustpin.cloud</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
    </dict>
</dict>
```

#### macOS
For sandboxed macOS apps, add the network client entitlement to your entitlements files:

```xml
<!-- In DebugProfile.entitlements and Release.entitlements -->
<key>com.apple.security.network.client</key>
<true/>
```

For non-sandboxed apps, network access is enabled by default.

## 🚀 Quick Start

### 1. Get Your Credentials

First, sign up at [TrustPin Cloud Console](https://app.trustpin.cloud) and create a project to get your:
- Organization ID
- Project ID  
- Public Key (ECDSA P-256, Base64-encoded)

### 2. Initialize the SDK

```dart
import 'package:trustpin_sdk/trustpin_sdk.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TrustPinSDK _trustPin = TrustPinSDK();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTrustPin();
  }

  Future<void> _initializeTrustPin() async {
    try {
      // Set debug logging for development
      await _trustPin.setLogLevel(TrustPinLogLevel.debug);
      
      // Initialize with your credentials
      await _trustPin.setup(
        organizationId: 'your-org-id',
        projectId: 'your-project-id',
        publicKey: 'LS0tLS1CRUdJTi...', // Your Base64 public key
        mode: TrustPinMode.strict, // Use strict mode for production
      );
      
      setState(() {
        _isInitialized = true;
      });
      
      print('TrustPin SDK initialized successfully!');
    } catch (e) {
      print('Failed to initialize TrustPin: $e');
    }
  }
}
```

### 3. Verify Certificates

```dart
Future<void> verifyServerCertificate() async {
  if (!_isInitialized) {
    print('TrustPin not initialized yet');
    return;
  }

  // Example PEM certificate (in practice, you'd get this from your HTTP client)
  const pemCertificate = '''
-----BEGIN CERTIFICATE-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7Q1jx8...
-----END CERTIFICATE-----
''';

  try {
    await _trustPin.verify('api.example.com', pemCertificate);
    print('✅ Certificate is valid and matches configured pins!');
  } on TrustPinException catch (e) {
    print('❌ Certificate verification failed: ${e.code} - ${e.message}');
    
    // Handle specific error types
    if (e.isPinsMismatch) {
      print('The certificate doesn\'t match any configured pins');
    } else if (e.isDomainNotRegistered) {
      print('Domain not configured for pinning (strict mode)');
    } else if (e.isAllPinsExpired) {
      print('All configured pins have expired');
    }
  } catch (e) {
    print('Unexpected error: $e');
  }
}
```

## 💼 Advanced Usage

### Integration with HTTP Clients

#### Using with Dio

```dart
import 'package:dio/dio.dart';
import 'package:trustpin_sdk/trustpin_sdk.dart';

class TrustPinInterceptor extends Interceptor {
  final TrustPinSDK _trustPin;
  
  TrustPinInterceptor(this._trustPin);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final uri = response.requestOptions.uri;
    
    if (uri.scheme == 'https') {
      try {
        // In a real implementation, you'd extract the certificate from the response
        // This is a simplified example
        final certificate = await _getCertificateFromResponse(response);
        await _trustPin.verify(uri.host, certificate);
        print('Certificate verified for ${uri.host}');
      } catch (e) {
        print('Certificate verification failed for ${uri.host}: $e');
        // Decide whether to reject the response or allow it
      }
    }
    
    handler.next(response);
  }
  
  Future<String> _getCertificateFromResponse(Response response) async {
    // Implementation depends on your HTTP client setup
    // You might need to configure the HTTP client to capture certificates
    throw UnimplementedError('Certificate extraction needs to be implemented based on your HTTP client setup');
  }
}

// Usage
final dio = Dio();
dio.interceptors.add(TrustPinInterceptor(_trustPin));
```

#### Using with http package

```dart
import 'dart:io';
import 'package:http/http.dart' as http;

class TrustPinHttpClient extends http.BaseClient {
  final http.Client _client;
  final TrustPinSDK _trustPin;
  
  TrustPinHttpClient(this._trustPin) : _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Custom HttpClient with certificate callback
    final client = HttpClient();
    
    client.badCertificateCallback = (cert, host, port) {
      // Convert X509Certificate to PEM format
      final pemCert = _x509ToPem(cert);
      
      try {
        // Verify certificate synchronously (note: this blocks the callback)
        // In production, you might want to implement this differently
        _trustPin.verify(host, pemCert);
        return true; // Certificate is valid
      } catch (e) {
        print('Certificate verification failed for $host: $e');
        return false; // Reject certificate
      }
    };
    
    // Continue with normal HTTP processing
    return _client.send(request);
  }
  
  String _x509ToPem(X509Certificate cert) {
    // Convert X509Certificate to PEM format
    // This is a simplified implementation
    final derBytes = cert.der;
    final base64String = base64Encode(derBytes);
    return '-----BEGIN CERTIFICATE-----\n$base64String\n-----END CERTIFICATE-----';
  }
  
  @override
  void close() {
    _client.close();
  }
}

// Usage
final httpClient = TrustPinHttpClient(_trustPin);
final response = await httpClient.get(Uri.parse('https://api.example.com/data'));
```

### Environment-Specific Configuration

```dart
class TrustPinConfig {
  static Future<void> initializeForEnvironment(TrustPinSDK trustPin) async {
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    
    switch (environment) {
      case 'production':
        await _initializeProduction(trustPin);
        break;
      case 'staging':
        await _initializeStaging(trustPin);
        break;
      default:
        await _initializeDevelopment(trustPin);
    }
  }
  
  static Future<void> _initializeProduction(TrustPinSDK trustPin) async {
    await trustPin.setLogLevel(TrustPinLogLevel.error);
    await trustPin.setup(
      organizationId: 'prod-org-123',
      projectId: 'prod-project-456',
      publicKey: 'LS0tLS1CRUdJTi...', // Production public key
      mode: TrustPinMode.strict,
    );
  }
  
  static Future<void> _initializeStaging(TrustPinSDK trustPin) async {
    await trustPin.setLogLevel(TrustPinLogLevel.info);
    await trustPin.setup(
      organizationId: 'staging-org-123',
      projectId: 'staging-project-456', 
      publicKey: 'LS0tLS1CRUdJTi...', // Staging public key
      mode: TrustPinMode.strict,
    );
  }
  
  static Future<void> _initializeDevelopment(TrustPinSDK trustPin) async {
    await trustPin.setLogLevel(TrustPinLogLevel.debug);
    await trustPin.setup(
      organizationId: 'dev-org-123',
      projectId: 'dev-project-456',
      publicKey: 'LS0tLS1CRUdJTi...', // Development public key
      mode: TrustPinMode.permissive, // Allow unpinned domains in development
    );
  }
}

// Usage in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final trustPin = TrustPinSDK();
  await TrustPinConfig.initializeForEnvironment(trustPin);
  
  runApp(MyApp());
}
```

### Error Handling Patterns

```dart
class TrustPinErrorHandler {
  static void handleVerificationError(TrustPinException error, String domain) {
    // Log error for monitoring
    _logSecurityEvent(error, domain);
    
    switch (error.code) {
      case 'PINS_MISMATCH':
        _handlePinsMismatch(error, domain);
        break;
      case 'DOMAIN_NOT_REGISTERED':
        _handleDomainNotRegistered(error, domain);
        break;
      case 'ALL_PINS_EXPIRED':
        _handleAllPinsExpired(error, domain);
        break;
      case 'INVALID_SERVER_CERT':
        _handleInvalidCertificate(error, domain);
        break;
      case 'ERROR_FETCHING_PINNING_INFO':
        _handleNetworkError(error, domain);
        break;
      default:
        _handleUnknownError(error, domain);
    }
  }
  
  static void _handlePinsMismatch(TrustPinException error, String domain) {
    // Critical security issue - potential MITM attack
    print('🚨 SECURITY ALERT: Certificate mismatch for $domain');
    // Consider blocking the request and alerting the user
  }
  
  static void _handleDomainNotRegistered(TrustPinException error, String domain) {
    print('⚠️ Domain $domain not configured for pinning');
    // In strict mode, this might be intentional or an oversight
  }
  
  static void _handleAllPinsExpired(TrustPinException error, String domain) {
    print('⏰ All pins expired for $domain - update needed');
    // Consider allowing the request but log for monitoring
  }
  
  static void _handleInvalidCertificate(TrustPinException error, String domain) {
    print('❌ Invalid certificate format for $domain');
    // This might indicate a parsing issue
  }
  
  static void _handleNetworkError(TrustPinException error, String domain) {
    print('🌐 Network error fetching pinning configuration');
    // Consider using cached configuration or fallback behavior
  }
  
  static void _handleUnknownError(TrustPinException error, String domain) {
    print('❓ Unknown error for $domain: ${error.message}');
    // Log for investigation
  }
  
  static void _logSecurityEvent(TrustPinException error, String domain) {
    // Send to your security monitoring system
    final event = {
      'timestamp': DateTime.now().toIso8601String(),
      'domain': domain,
      'error_code': error.code,
      'error_message': error.message,
      'app_version': 'your-app-version',
    };
    
    // Send to your logging/monitoring service
    print('Security event logged: $event');
  }
}

// Usage
try {
  await trustPin.verify('api.example.com', certificate);
} on TrustPinException catch (e) {
  TrustPinErrorHandler.handleVerificationError(e, 'api.example.com');
  // Decide whether to proceed with the request or abort
  rethrow; // Re-throw if you want to abort the request
}
```

## 📚 API Documentation

For complete API documentation, visit our **[GitHub Pages Documentation](https://trustpin-cloud.github.io/TrustPin-Flutter.code/)**.

### TrustPinSDK

#### setup()

Initializes the TrustPin SDK with your project credentials.

```dart
Future<void> setup({
  required String organizationId,
  required String projectId,
  required String publicKey,
  TrustPinMode mode = TrustPinMode.strict,
})
```

**Parameters:**
- `organizationId`: Your organization identifier from the TrustPin dashboard
- `projectId`: Your project identifier from the TrustPin dashboard
- `publicKey`: Base64-encoded ECDSA P-256 public key for JWS verification
- `mode`: Pinning mode (strict or permissive)

**Throws:** `TrustPinException` if setup fails

#### verify()

Verifies a certificate against the configured pins for a domain.

```dart
Future<void> verify(String domain, String certificate)
```

**Parameters:**
- `domain`: The domain name to verify (e.g., "api.example.com")
- `certificate`: PEM-encoded certificate string with BEGIN/END markers

**Throws:** `TrustPinException` if verification fails

#### setLogLevel()

Sets the logging level for TrustPin SDK.

```dart
Future<void> setLogLevel(TrustPinLogLevel level)
```

### Enums

#### TrustPinMode

Pinning modes that control behavior for unregistered domains:

- `TrustPinMode.strict`: Throws errors for unregistered domains (recommended for production)
- `TrustPinMode.permissive`: Allows unregistered domains to bypass pinning (development/testing)

#### TrustPinLogLevel

Log levels for controlling SDK output verbosity:

- `TrustPinLogLevel.none`: No logging output
- `TrustPinLogLevel.error`: Only error messages
- `TrustPinLogLevel.info`: Error and informational messages
- `TrustPinLogLevel.debug`: All messages including debug information

### Exception Handling

#### TrustPinException

Exception thrown by TrustPin operations with detailed error information:

**Properties:**
- `code`: Error code identifying the type of error
- `message`: Human-readable error message
- `details`: Additional error details (may be null)

**Error Types:**
- `INVALID_PROJECT_CONFIG`: Invalid setup parameters
- `ERROR_FETCHING_PINNING_INFO`: CDN fetch failure
- `INVALID_SERVER_CERT`: Invalid certificate format
- `PINS_MISMATCH`: Certificate doesn't match configured pins
- `ALL_PINS_EXPIRED`: All configured pins have expired
- `JWS_VALIDATION_FAILED`: JWS signature validation failed
- `DOMAIN_NOT_REGISTERED`: Domain not configured (strict mode only)
- `CONFIGURATION_VALIDATION_FAILED`: Configuration validation failed

**Helper Methods:**
```dart
// Check specific error types
if (exception.isPinsMismatch) {
  // Handle certificate mismatch
}

if (exception.isDomainNotRegistered) {
  // Handle unregistered domain in strict mode
}
```

## Example

See the `example/` directory for a complete sample application that demonstrates:

- SDK initialization with credentials
- Certificate verification
- Error handling
- Log level configuration

## Security Considerations

### Production Deployment

1. **Use Strict Mode**: Always use `TrustPinMode.strict` in production
2. **Secure Credentials**: Never commit credentials to version control
3. **Minimal Logging**: Use `TrustPinLogLevel.error` or `none` in production
4. **Regular Updates**: Keep pinning configurations up to date

### Development and Testing

1. **Permissive Mode**: Use `TrustPinMode.permissive` for development
2. **Debug Logging**: Enable `TrustPinLogLevel.debug` for troubleshooting
3. **Test Environment**: Use separate credentials for testing

## Platform-Specific Implementation

### iOS

- Uses TrustPin Swift SDK from https://github.com/trustpin-cloud/TrustPin-Swift.binary
- Supports iOS 13.0 and later
- Built with Swift 5.0+
- Async/await support for modern Swift concurrency

### macOS

- Uses TrustPin Swift SDK from https://github.com/trustpin-cloud/TrustPin-Swift.binary
- Supports macOS 13.0 and later
- Built with Swift 5.0+
- Async/await support for modern Swift concurrency
- Sandboxing compatible with proper entitlements

### Android

- Uses TrustPin Kotlin SDK from Maven (`cloud.trustpin:kotlin-sdk:<<version>>`)
- Supports Android API 21 and later
- Built with Kotlin coroutines
- Multiplatform support (Android/JVM)

## 🔐 Security Best Practices

### Production Checklist

- ✅ Use `TrustPinMode.strict` mode
- ✅ Set log level to `TrustPinLogLevel.error` or `none`
- ✅ Store credentials securely (not in source code)
- ✅ Implement proper error handling for certificate failures
- ✅ Monitor certificate validation errors
- ✅ Keep pinning configurations up to date
- ✅ Test certificate validation in staging environment

### Development Tips

- 🔧 Use `TrustPinMode.permissive` for development
- 🔧 Enable `TrustPinLogLevel.debug` for troubleshooting
- 🔧 Use separate credentials for different environments
- 🔧 Test with both valid and invalid certificates
- 🔧 Verify error handling works correctly

## 📊 Performance Considerations

- **Configuration Caching**: Pinning configurations are cached for 10 minutes
- **Network Optimization**: Initial setup requires one CDN request
- **Memory Usage**: Minimal memory footprint with efficient native implementations
- **CPU Impact**: Certificate validation is highly optimized in native code
- **Battery Life**: Negligible impact on battery consumption

## 🧪 Testing

The plugin includes comprehensive test coverage:

```bash
# Run unit tests
flutter test

# Run integration tests (requires device/emulator)
cd example
flutter test integration_test/plugin_integration_test.dart

# Run with coverage
flutter test --coverage
```

## 📱 Example App

The `example/` directory contains a complete sample application demonstrating:

- SDK initialization with different configurations
- Certificate verification with various scenarios
- Error handling patterns
- Integration with HTTP clients
- Environment-specific setup

To run the example:

```bash
cd example
flutter pub get
flutter run
```

## 🚀 Migration Guide

### From Direct Native SDK Usage

If you're currently using the native TrustPin SDKs directly:

1. **Replace native SDK imports**:
   ```dart
   // Remove native imports
   // iOS: import TrustPinKit
   // Android: import cloud.trustpin.kotlin.sdk.TrustPin
   
   // Add Flutter plugin
   import 'package:trustpin_sdk/trustpin_sdk.dart';
   ```

2. **Update initialization**:
   ```dart
   // Old (iOS)
   // try await TrustPin.setup(organizationId: "...", projectId: "...", publicKey: "...", mode: .strict)
   
   // Old (Android)  
   // val trustPin = TrustPin.create()
   // trustPin.setup("...", "...", "...")
   
   // New (Flutter)
   final trustPin = TrustPinSDK();
   await trustPin.setup(
     organizationId: 'your-org-id',
     projectId: 'your-project-id',
     publicKey: 'your-public-key',
     mode: TrustPinMode.strict,
   );
   ```

3. **Update certificate verification**:
   ```dart
   // Old (iOS)
   // try await TrustPin.verify(domain: "api.example.com", certificate: pemCert)
   
   // Old (Android)
   // trustPin.verify("api.example.com", x509Certificate)
   
   // New (Flutter)
   await trustPin.verify('api.example.com', pemCertificate);
   ```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](./devs/README.md) for detailed information about:

- Development environment setup
- Code style guidelines
- Testing requirements
- Pull request process

### Quick Contribution Steps

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Make changes** with tests
4. **Run quality checks**: 
   ```bash
   dart analyze --fatal-infos
   dart format --set-exit-if-changed .
   flutter test
   ```
5. **Create pull request** with clear description

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support & Community

### Getting Help

- 📖 **Documentation**: [GitHub Pages](https://trustpin-cloud.github.io/TrustPin-Flutter.code/)
- 📖 **API Reference**: [pub.dev/documentation/trustpin_sdk](https://pub.dev/documentation/trustpin_sdk/latest/)
- 🐛 **Issues**: [GitHub Issues](https://github.com/trustpin-cloud/trustpin-libraries/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/trustpin-cloud/trustpin-libraries/discussions)

### Professional Support

- 📧 **Email**: support@trustpin.cloud
- 🌐 **Website**: [trustpin.cloud](https://trustpin.cloud)
- 📚 **Documentation**: [docs.trustpin.cloud](https://docs.trustpin.cloud)
- 🎯 **Cloud Console**: [app.trustpin.cloud](https://app.trustpin.cloud)

### Stay Updated

- ⭐ **Star** this repository to stay updated with releases
- 👀 **Watch** for important security updates
- 📢 **Follow** [@TrustPinCloud](https://twitter.com/TrustPinCloud) on Twitter

---

<div align="center">

**🔒 Secure your Flutter apps with TrustPin SSL Certificate Pinning 🔒**

[Get Started](https://app.trustpin.cloud) • [Documentation](https://trustpin-cloud.github.io/TrustPin-Flutter.code/) • [Support](mailto:support@trustpin.cloud)

</div>

