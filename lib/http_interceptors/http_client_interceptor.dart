import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../trustpin_sdk.dart';

/// A certificate pinning interceptor for the http package.
///
/// This interceptor wraps any http.Client and adds TrustPin certificate
/// validation to all HTTPS requests. It first ensures the certificate passes
/// standard TLS validation, then performs additional TrustPin verification.
///
/// Certificates are cached to avoid repeated socket connections to the same
/// host. The cache stores certificates but not validation results, so TrustPin
/// verification is performed on every request.
class TrustPinHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, X509Certificate> _certificateCache = {};

  /// Creates a new TrustPinHttpClient that wraps the provided client.
  ///
  /// The [inner] client will be used for making actual HTTP requests after
  /// certificate validation passes. TrustPin must be properly configured
  /// with [TrustPin.setup] before making requests.
  TrustPinHttpClient(this._inner);

  /// Creates a TrustPinHttpClient with a default http.Client.
  ///
  /// This is a convenience constructor that creates a standard http.Client
  /// internally. TrustPin must be properly configured with [TrustPin.setup]
  /// before making requests.
  factory TrustPinHttpClient.create() {
    return TrustPinHttpClient(http.Client());
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final uri = request.url;

    // Only validate HTTPS requests
    if (uri.scheme == 'https') {
      await _validateCertificate(uri.host, uri.port);
    }

    return _inner.send(request);
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
    // onBadCertificate: false ensures standard TLS validation happens first
    SecureSocket? socket;
    try {
      socket = await SecureSocket.connect(
        host,
        port,
        onBadCertificate: (cert) => false,
        // Reject invalid certs - standard validation first
        timeout: const Duration(seconds: 10),
      );

      // If we reach here, the certificate passed standard TLS validation
      // Now perform additional TrustPin verification
      final cert = socket.peerCertificate;
      if (cert != null) {
        // Cache the certificate for future requests
        _certificateCache[cacheKey] = cert;

        final pemCert = _formatCertificateToPem(cert);
        await TrustPin.verify(host, pemCert);
      }
    } on SocketException catch (e) {
      // Certificate failed standard TLS validation
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

  @override
  void close() {
    _certificateCache.clear();
    _inner.close();
  }
}
