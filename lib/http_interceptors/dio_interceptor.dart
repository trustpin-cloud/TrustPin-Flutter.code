import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../trustpin_sdk.dart';

/// A certificate pinning interceptor for the Dio HTTP client.
///
/// This interceptor adds TrustPin certificate validation to all HTTPS requests
/// made through Dio. It validates certificates in two phases:
/// 1. Standard TLS validation (handled by the OS)
/// 2. TrustPin certificate pinning validation
///
/// Certificates are cached to avoid repeated socket connections to the same
/// host. The cache stores certificates but not validation results, so TrustPin
/// verification is performed on every request.
///
/// ## Usage
///
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(TrustPinDioInterceptor());
///
/// // Now all HTTPS requests will have certificate pinning
/// final response = await dio.get('https://api.example.com/data');
/// ```
///
/// ## Important Notes
///
/// - TrustPin must be initialized with [TrustPin.setup] before using this interceptor
/// - Only HTTPS requests are validated; HTTP requests pass through unchanged
/// - Certificate validation happens before the actual HTTP request is sent
/// - Failed validation prevents the request from being sent
class TrustPinDioInterceptor extends Interceptor {
  final Map<String, X509Certificate> _certificateCache = {};

  /// Creates a new TrustPinDioInterceptor.
  ///
  /// TrustPin must be properly configured with [TrustPin.setup] before
  /// making requests with this interceptor.
  TrustPinDioInterceptor();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final uri = options.uri;

    // Only validate HTTPS requests
    if (uri.scheme == 'https') {
      try {
        await _validateCertificate(uri.host, uri.port);
        // Certificate validation passed, proceed with request
        handler.next(options);
      } on TrustPinException catch (e) {
        // Certificate validation failed, reject the request
        handler.reject(
          DioException(
            requestOptions: options,
            error: e,
            type: DioExceptionType.connectionError,
            message: 'Certificate pinning validation failed',
          ),
        );
      } catch (e) {
        // Other errors during validation
        handler.reject(
          DioException(
            requestOptions: options,
            error: e,
            type: DioExceptionType.connectionError,
            message: 'Certificate pinning validation failed',
          ),
        );
      }
    } else {
      // Not HTTPS, proceed without validation
      handler.next(options);
    }
  }

  Future<void> _validateCertificate(String host, int port) async {
    final cacheKey = '$host:$port';

    // Check if we have a cached certificate for this host
    final cachedCert = _certificateCache[cacheKey];
    if (cachedCert != null) {
      // Use cached certificate for validation
      final pemCert = _formatCertificateToPem(cachedCert);
      await TrustPin.verify(host, pemCert);
      return;
    }

    // Create a secure socket connection to get the certificate
    // We don't override onBadCertificate - let standard TLS validation happen
    SecureSocket? socket;
    try {
      socket = await SecureSocket.connect(
        host,
        port,
        timeout: const Duration(seconds: 10),
        // Not setting onBadCertificate means it defaults to rejecting bad certificates
      );

      // If we reach here, the certificate passed standard TLS validation
      // Now perform additional TrustPin verification
      final cert = socket.peerCertificate;
      if (cert != null) {
        // Cache the certificate for future requests
        _certificateCache[cacheKey] = cert;

        final pemCert = _formatCertificateToPem(cert);
        await TrustPin.verify(host, pemCert);
      } else {
        throw TrustPinException(
          'NO_CERTIFICATE',
          'No certificate received from server',
        );
      }
    } on SocketException catch (e) {
      // Certificate failed standard TLS validation or connection failed
      throw TrustPinException(
        'TLS_VALIDATION_FAILED',
        'Certificate failed standard TLS validation: ${e.message}',
      );
    } on HandshakeException catch (e) {
      // TLS handshake failed
      throw TrustPinException(
        'TLS_HANDSHAKE_FAILED',
        'TLS handshake failed: ${e.message}',
      );
    } finally {
      socket?.destroy();
    }
  }

  String _formatCertificateToPem(X509Certificate cert) {
    final derBytes = cert.der;
    final base64Cert = base64Encode(derBytes);

    // Format as PEM with proper line breaks
    final buffer = StringBuffer();
    buffer.writeln('-----BEGIN CERTIFICATE-----');

    // Split base64 into 64-character lines
    for (int i = 0; i < base64Cert.length; i += 64) {
      final end = (i + 64 < base64Cert.length) ? i + 64 : base64Cert.length;
      buffer.writeln(base64Cert.substring(i, end));
    }

    buffer.writeln('-----END CERTIFICATE-----');
    return buffer.toString();
  }

  /// Clears the certificate cache.
  ///
  /// Call this method if you want to force fetching fresh certificates
  /// for all hosts on the next request.
  void clearCertificateCache() {
    _certificateCache.clear();
  }
}
