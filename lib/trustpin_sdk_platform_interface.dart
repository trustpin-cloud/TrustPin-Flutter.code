import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'trustpin_sdk_method_channel.dart';

abstract class TrustPinSDKPlatform extends PlatformInterface {
  /// Constructs a TrustPinSDKPlatform.
  TrustPinSDKPlatform() : super(token: _token);

  static final Object _token = Object();

  static TrustPinSDKPlatform _instance = MethodChannelTrustPinSDK();

  /// The default instance of [TrustPinSDKPlatform] to use.
  ///
  /// Defaults to [MethodChannelTrustPinSDK].
  static TrustPinSDKPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TrustPinSDKPlatform] when
  /// they register themselves.
  static set instance(TrustPinSDKPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> setup(
    String organizationId,
    String projectId,
    String publicKey, {
    Uri? configurationURL,
    String mode = 'strict',
  }) {
    throw UnimplementedError('setup() has not been implemented.');
  }

  Future<void> verify(String domain, String certificate) {
    throw UnimplementedError('verify() has not been implemented.');
  }

  Future<void> setLogLevel(String logLevel) {
    throw UnimplementedError('setLogLevel() has not been implemented.');
  }
}
