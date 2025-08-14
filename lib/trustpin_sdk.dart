import 'trustpin_exception.dart';
import 'trustpin_log_level.dart';
import 'trustpin_mode.dart';
import 'trustpin_sdk_platform_interface.dart';

export 'http_interceptors/dio_interceptor.dart';
export 'http_interceptors/http_client_interceptor.dart';
export 'trustpin_exception.dart';
export 'trustpin_log_level.dart';
export 'trustpin_mode.dart';

/// TrustPin SSL certificate pinning SDK for Flutter applications.
///
/// TrustPin provides SSL certificate pinning functionality to prevent man-in-the-middle (MITM) attacks
/// by validating server certificates against pre-configured public key pins. The library supports
/// both strict and permissive validation modes to accommodate different security requirements.
///
/// ## Overview
///
/// TrustPin uses JSON Web Signature (JWS) based configuration to securely deliver pinning
/// configurations to your Flutter application. The SDK fetches signed pinning configuration
/// from the TrustPin CDN and validates certificates against SHA-256 or SHA-512 hashes.
///
/// ## Key Features
/// - **JWS-based Configuration**: Fetches signed pinning configuration from TrustPin CDN
/// - **Certificate Validation**: Supports SHA-256 and SHA-512 certificate hashing
/// - **Signature Verification**: Validates JWS signatures using ECDSA P-256
/// - **Intelligent Caching**: Caches configuration for 10 minutes with stale fallback
/// - **Thread Safety**: All operations are thread-safe and work with Flutter's async model
/// - **Configurable Logging**: Multiple log levels for debugging and monitoring
/// - **Cross-Platform**: Works on iOS, Android, and macOS with native implementations
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:trustpin_sdk/trustpin_sdk.dart';
///
/// // TrustPin is a singleton - no instantiation needed
///
/// // Initialize TrustPin with your project credentials
/// await TrustPin.setup(
///   organizationId: 'your-org-id',
///   projectId: 'your-project-id',
///   publicKey: 'your-base64-public-key',
///   mode: TrustPinMode.strict, // Use strict mode in production
/// );
///
/// // Verify a certificate manually
/// final pemCertificate = '''
/// -----BEGIN CERTIFICATE-----
/// MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
/// -----END CERTIFICATE-----
/// ''';
///
/// try {
///   await TrustPin.verify('api.example.com', pemCertificate);
///   print('Certificate is valid!');
/// } catch (e) {
///   print('Certificate validation failed: $e');
/// }
/// ```
///
/// ## Integration with HTTP Clients
///
/// For automatic certificate validation, integrate TrustPin with your HTTP client:
///
/// ```dart
/// import 'dart:io';
/// import 'package:http/http.dart' as http;
///
/// // Custom HttpClient with certificate callback
/// class TrustPinHttpClient extends http.BaseClient {
///   final http.Client _client = http.Client();
///   final TrustPinSDK _trustPin = TrustPinSDK();
///
///   @override
///   Future<http.StreamedResponse> send(http.BaseRequest request) async {
///     // Validate certificate before making request
///     final uri = request.url;
///     if (uri.scheme == 'https') {
///       // Get certificate from connection and verify
///       // Implementation depends on your HTTP client setup
///     }
///     return _client.send(request);
///   }
/// }
/// ```
///
/// ## Pinning Modes
///
/// - [TrustPinMode.strict]: Throws errors for unregistered domains (recommended for production)
/// - [TrustPinMode.permissive]: Allows unregistered domains to bypass pinning (development/testing)
///
/// ## Error Handling
///
/// TrustPin provides detailed error information through [TrustPinException] for proper
/// error handling and security monitoring. All errors include specific error codes
/// that can be checked programmatically:
///
/// ```dart
/// try {
///   await trustPin.verify('api.example.com', certificate);
/// } on TrustPinException catch (e) {
///   if (e.isDomainNotRegistered) {
///     print('Domain not configured for pinning');
///   } else if (e.isPinsMismatch) {
///     print('Certificate doesn\'t match configured pins');
///   } else if (e.isAllPinsExpired) {
///     print('All pins for this domain have expired');
///   }
///   // Handle other error types...
/// }
/// ```
///
/// ## Security Considerations
///
/// - **Production**: Always use [TrustPinMode.strict] mode to ensure all connections are validated
/// - **Development**: Use [TrustPinMode.permissive] mode to allow connections to unregistered domains
/// - **Credentials**: Keep your public key secure and never commit it to version control in plain text
/// - **Network**: Ensure your app can reach `https://cdn.trustpin.cloud` for configuration updates
///
/// ## Thread Safety
///
/// All TrustPin operations are thread-safe and can be called from any isolate.
/// Internal operations are performed on appropriate background threads through
/// the native platform implementations.
///
/// - Note: Always call [setup] before performing certificate verification.
/// - Important: Use [TrustPinMode.strict] mode in production environments for maximum security.
class TrustPin {
  // Private constructor to prevent instantiation
  TrustPin._();

  /// Initializes the TrustPin SDK with the specified configuration.
  ///
  /// This method configures TrustPin with your organization credentials and fetches
  /// the pinning configuration from the TrustPin service. The configuration is cached
  /// for 10 minutes to optimize performance and reduce network requests.
  ///
  /// ## Example Usage
  ///
  /// ```dart
  /// // Production setup with strict mode
  /// await TrustPin.setup(
  ///   organizationId: 'prod-org-123',
  ///   projectId: 'mobile-app-v2',
  ///   publicKey: 'LS0tLS1CRUdJTi...',
  ///   mode: TrustPinMode.strict,
  /// );
  ///
  /// // Development setup with permissive mode
  /// await TrustPin.setup(
  ///   organizationId: 'dev-org-456',
  ///   projectId: 'mobile-app-staging',
  ///   publicKey: 'LS0tLS1CRUdJTk...',
  ///   mode: TrustPinMode.permissive,
  /// );
  /// ```
  ///
  /// ## Security Considerations
  ///
  /// - **Production**: Always use [TrustPinMode.strict] mode to ensure all connections are validated
  /// - **Development**: Use [TrustPinMode.permissive] mode to allow connections to unregistered domains
  /// - **Credentials**: Keep your public key secure and never commit it to version control in plain text
  ///
  /// ## Network Requirements
  ///
  /// This method requires network access to fetch the pinning configuration from
  /// `https://cdn.trustpin.cloud`. Ensure your app has appropriate network permissions
  /// and can reach this endpoint.
  ///
  /// - Parameter [organizationId]: Your organization identifier from the TrustPin dashboard
  /// - Parameter [projectId]: Your project identifier from the TrustPin dashboard
  /// - Parameter [publicKey]: Base64-encoded ECDSA P-256 public key for JWS signature verification
  /// - Parameter [configurationURL]: Custom URL for the signed payload (JWS). CDN Managed project should not use this method. Defaults to *null* for CDN Managed Projects
  /// - Parameter [mode]: The pinning mode controlling behavior for unregistered domains (default: [TrustPinMode.strict])
  ///
  /// - Throws [TrustPinException] with code `INVALID_PROJECT_CONFIG` if credentials are invalid or empty
  /// - Throws [TrustPinException] with code `ERROR_FETCHING_PINNING_INFO` if network request fails
  /// - Throws [TrustPinException] with code `JWS_VALIDATION_FAILED` if JWS signature verification fails
  ///
  /// - Important: This method must be called before any certificate verification operations.
  /// - Note: Configuration is automatically cached for 10 minutes to improve performance.
  static Future<void> setup({
    required String organizationId,
    required String projectId,
    required String publicKey,
    Uri? configurationURL,
    TrustPinMode mode = TrustPinMode.strict,
  }) async {
    try {
      await TrustPinSDKPlatform.instance.setup(
        organizationId,
        projectId,
        publicKey,
        configurationURL: configurationURL,
        mode: mode.value,
      );
    } catch (e) {
      throw TrustPinException.fromPlatformException(e);
    }
  }

  /// Verifies a certificate against the specified domain using public key pinning.
  ///
  /// This method performs certificate validation by comparing the certificate's public key
  /// against the configured pins for the specified domain. It supports both SHA-256 and
  /// SHA-512 hash algorithms for pin matching.
  ///
  /// ## Example Usage
  ///
  /// ```dart
  /// final pemCertificate = '''
  /// -----BEGIN CERTIFICATE-----
  /// MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
  /// -----END CERTIFICATE-----
  /// ''';
  ///
  /// try {
  ///   await TrustPin.verify('api.example.com', pemCertificate);
  ///   print('Certificate is valid!');
  /// } on TrustPinException catch (e) {
  ///   if (e.isDomainNotRegistered) {
  ///     print('Domain not configured for pinning');
  ///   } else if (e.isPinsMismatch) {
  ///     print('Certificate doesn\'t match configured pins');
  ///   }
  ///   // Handle other error types...
  /// }
  /// ```
  ///
  /// ## Security Behavior
  ///
  /// - **Registered domains**: Certificate validation is performed against configured pins
  /// - **Unregistered domains**: Behavior depends on the configured [TrustPinMode]:
  ///   - [TrustPinMode.strict]: Throws [TrustPinException] with code `DOMAIN_NOT_REGISTERED`
  ///   - [TrustPinMode.permissive]: Allows connection to proceed with info log
  ///
  /// ## Certificate Format
  ///
  /// The certificate must be in PEM format, including the BEGIN and END markers.
  /// Both single and multiple certificate chains are supported. The leaf certificate
  /// (first certificate in the chain) is used for validation.
  ///
  /// - Parameter [domain]: The domain name to validate (e.g., "api.example.com", will be sanitized)
  /// - Parameter [certificate]: PEM-encoded certificate string with BEGIN/END markers
  ///
  /// - Throws [TrustPinException] with code `DOMAIN_NOT_REGISTERED` if domain is not configured (strict mode only)
  /// - Throws [TrustPinException] with code `PINS_MISMATCH` if certificate doesn't match any configured pins
  /// - Throws [TrustPinException] with code `ALL_PINS_EXPIRED` if all pins for the domain have expired
  /// - Throws [TrustPinException] with code `INVALID_SERVER_CERT` if certificate format is invalid
  /// - Throws [TrustPinException] with code `INVALID_PROJECT_CONFIG` if [setup] has not been called
  ///
  /// - Important: Call [setup] before using this method.
  /// - Note: This method is thread-safe and can be called from any isolate.
  static Future<void> verify(String domain, String certificate) async {
    try {
      await TrustPinSDKPlatform.instance.verify(domain, certificate);
    } catch (e) {
      throw TrustPinException.fromPlatformException(e);
    }
  }

  /// Sets the current log level for TrustPin's internal logging system.
  ///
  /// Logging helps with debugging certificate pinning issues and monitoring
  /// security events. Different log levels provide varying amounts of detail.
  ///
  /// ## Log Levels
  ///
  /// - [TrustPinLogLevel.none]: No logging output
  /// - [TrustPinLogLevel.error]: Only error messages
  /// - [TrustPinLogLevel.info]: Errors and informational messages
  /// - [TrustPinLogLevel.debug]: All messages including detailed debug information
  ///
  /// ## Example Usage
  ///
  /// ```dart
  /// // Enable debug logging for development
  /// await TrustPin.setLogLevel(TrustPinLogLevel.debug);
  ///
  /// // Minimal logging for production
  /// await TrustPin.setLogLevel(TrustPinLogLevel.error);
  ///
  /// // Disable all logging
  /// await TrustPin.setLogLevel(TrustPinLogLevel.none);
  /// ```
  ///
  /// ## Performance Considerations
  ///
  /// - **Production**: Use [TrustPinLogLevel.error] or [TrustPinLogLevel.none] to minimize performance impact
  /// - **Development**: Use [TrustPinLogLevel.debug] for detailed troubleshooting information
  /// - **Staging**: Use [TrustPinLogLevel.info] for balanced logging without excessive detail
  ///
  /// - Parameter [level]: The [TrustPinLogLevel] to use for filtering log messages
  ///
  /// - Note: This setting affects all TrustPin logging globally across your application.
  /// - Important: Set the log level before calling [setup] for complete logging coverage.
  static Future<void> setLogLevel(TrustPinLogLevel level) async {
    try {
      await TrustPinSDKPlatform.instance.setLogLevel(level.value);
    } catch (e) {
      throw TrustPinException.fromPlatformException(e);
    }
  }
}
