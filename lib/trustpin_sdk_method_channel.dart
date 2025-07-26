import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'trustpin_sdk_platform_interface.dart';

/// An implementation of [TrustPinSDKPlatform] that uses method channels.
class MethodChannelTrustPinSDK extends TrustPinSDKPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('trustpin_sdk');

  @override
  Future<void> setup(
    String organizationId,
    String projectId,
    String publicKey, {
    Uri? configurationURL,
    String mode = 'strict',
  }) async {
    await methodChannel.invokeMethod('setup', {
      'organizationId': organizationId,
      'projectId': projectId,
      'publicKey': publicKey,
      'configurationURL': configurationURL?.toString(),
      'mode': mode,
    });
  }

  @override
  Future<void> verify(String domain, String certificate) async {
    await methodChannel.invokeMethod('verify', {
      'domain': domain,
      'certificate': certificate,
    });
  }

  @override
  Future<void> setLogLevel(String logLevel) async {
    await methodChannel.invokeMethod('setLogLevel', {'logLevel': logLevel});
  }
}
