# TrustPin SDK for Flutter

[![pub package](https://img.shields.io/pub/v/trustpin_sdk.svg)](https://pub.dev/packages/trustpin_sdk)
[![documentation](https://img.shields.io/badge/documentation-GitHub%20Pages-blue)](https://trustpin-cloud.github.io/TrustPin-Flutter.code/)
[![platform](https://img.shields.io/badge/platform-flutter-blue)](https://flutter.dev)
[![platform](https://img.shields.io/badge/platform-dart-blue)](https://dart.dev)

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
- **🚀 HTTP Client Integration**: Built-in interceptors for popular HTTP clients (http, Dio)

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

- **Minimum SDK**: API 25 (Android 5.0)+
- **Target SDK**: API 34+ (recommended)
- **Kotlin**: 2.3.0+
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
  @override
  void initState() {
    super.initState();
    _initializeTrustPin();
  }

  Future<void> _initializeTrustPin() async {
    try {
      // Set debug logging for development
      await TrustPin.setLogLevel(TrustPinLogLevel.debug);
      
      // Initialize with your credentials
      await TrustPin.setup(
        organizationId: 'your-org-id',
        projectId: 'your-project-id',
        publicKey: 'LS0tLS1CRUdJTi...', // Your Base64 public key
        mode: TrustPinMode.strict, // Use strict mode for production
      );
      
      print('TrustPin SDK initialized successfully!');
    } catch (e) {
      print('Failed to initialize TrustPin: $e');
    }
}
```

### 3. Verify Certificates

```dart
Future<void> verifyServerCertificate() async {
  // Example PEM certificate (in practice, you'd get this from your HTTP client)
  const pemCertificate = '''
-----BEGIN CERTIFICATE-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7Q1jx8...
-----END CERTIFICATE-----
''';

  try {
    await TrustPin.verify('api.example.com', pemCertificate);
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

The SDK provides a built-in `TrustPinDioInterceptor` for seamless Dio integration:

```dart
import 'package:dio/dio.dart';
import 'package:trustpin_sdk/trustpin_sdk.dart';

// Create Dio instance with TrustPin certificate validation
final dio = Dio();
dio.interceptors.add(TrustPinDioInterceptor());

// All HTTPS requests will now have certificate pinning validation
try {
  final response = await dio.get('https://api.example.com/data');
  print('Request successful: ${response.statusCode}');
} on DioException catch (e) {
  if (e.error is TrustPinException) {
    final trustPinError = e.error as TrustPinException;
    print('Certificate pinning failed: ${trustPinError.code} - ${trustPinError.message}');
  } else {
    print('Request failed: ${e.message}');
  }
}

// The interceptor automatically:
// 1. Validates standard TLS certificates (OS-level validation)
// 2. Performs TrustPin certificate pinning validation
// 3. Caches certificates for performance
// 4. Prevents requests with invalid certificates

// Manage certificate cache if needed
final interceptor = TrustPinDioInterceptor();
dio.interceptors.add(interceptor);

// Clear all cached certificates
interceptor.clearCertificateCache();
```

#### Using with http package  

The SDK provides a built-in `TrustPinHttpClient` that wraps the standard http.Client:

```dart
import 'package:http/http.dart' as http;
import 'package:trustpin_sdk/trustpin_sdk.dart';

// Create a TrustPin-enabled HTTP client
final httpClient = TrustPinHttpClient.create();

// Or wrap an existing client
final customClient = http.Client();
final httpClient = TrustPinHttpClient(customClient);

// Use it like a normal http.Client
final response = await httpClient.get(Uri.parse('https://api.example.com/data'));

// The client automatically:
// 1. Validates standard TLS certificates
// 2. Performs TrustPin certificate pinning
// 3. Caches certificates for performance

// Clear certificate cache if needed
httpClient.clearCertificateCache();

// Clean up when done
httpClient.close();
```

---

<div align="center">

**🔒 Secure your Flutter apps with TrustPin SSL Certificate Pinning 🔒**

[Get Started](https://app.trustpin.cloud) • [Documentation](https://trustpin-cloud.github.io/TrustPin-Flutter.code/) • [Support](mailto:support@trustpin.cloud)

</div>

---