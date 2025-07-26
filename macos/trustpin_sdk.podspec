Pod::Spec.new do |spec|
  spec.name             = 'trustpin_sdk'
  spec.version          = '1.0.0'
  spec.summary          = 'Flutter plugin for TrustPin SSL certificate pinning SDK'
  spec.description      = <<-DESC
Flutter plugin for TrustPin SSL certificate pinning SDK providing secure certificate validation.
                       DESC
  spec.homepage         = 'https://github.com/trustpin-cloud/TrustPin-Flutter'
  spec.license          = { :file => '../LICENSE' }
  spec.author           = { 'TrustPin' => 'support@trustpin.cloud' }
  spec.source           = { :git => 'https://github.com/trustpin-cloud/TrustPin-flutter.code' }
  spec.source_files = 'Classes/**/*'
  spec.dependency 'FlutterMacOS'
  spec.dependency 'TrustPinKit', '1.0.0'

  spec.osx.deployment_target = "13.0"

  # Flutter.framework does not contain a i386 slice.
  spec.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  spec.swift_version = "5.10"

  spec.framework = "Foundation"
end