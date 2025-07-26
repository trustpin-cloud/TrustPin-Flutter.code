import Flutter
import TrustPinKit
import UIKit

public class TrustPinSDKPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "trustpin_sdk", binaryMessenger: registrar.messenger())
    let instance = TrustPinSDKPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setup":
      handleSetup(call: call, result: result)
    case "verify":
      handleVerify(call: call, result: result)
    case "setLogLevel":
      handleSetLogLevel(call: call, result: result)
    default:
      Task { @MainActor in
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func handleSetup(call: FlutterMethodCall, result: @escaping FlutterResult) {
    Task {
      do {
        guard let args = call.arguments as? [String: Any],
              let organizationId = args["organizationId"] as? String,
              let projectId = args["projectId"] as? String,
              let publicKey = args["publicKey"] as? String
        else {
          await MainActor.run {
            result(
                FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Missing required arguments",
                    details: nil))
          }
          return
        }

        let configurationURL = args["configurationURL"] as? String
        let modeString = args["mode"] as? String ?? "strict"
        let mode: TrustPinMode = modeString == "permissive" ? .permissive : .strict

        if let configURLString = configurationURL, !configURLString.isEmpty,
           let url = URL(string: configURLString) {
          try await TrustPin.setup(
              organizationId: organizationId,
              projectId: projectId,
              publicKey: publicKey,
              configurationURL: url,
              mode: mode)
        } else {
          try await TrustPin.setup(
              organizationId: organizationId,
              projectId: projectId,
              publicKey: publicKey,
              mode: mode)
        }

        await MainActor.run {
          result(nil)
        }
      } catch let error as TrustPinErrors {
        await MainActor.run {
          result(
              FlutterError(
                  code: mapTrustPinError(error),
                  message: error.localizedDescription,
                  details: nil))
        }
      } catch {
        await MainActor.run {
          result(
              FlutterError(
                  code: "SETUP_ERROR",
                  message: error.localizedDescription,
                  details: nil))
        }
      }
    }
  }

  private func handleVerify(call: FlutterMethodCall, result: @escaping FlutterResult) {
    Task {
      do {
        guard let args = call.arguments as? [String: Any],
              let domain = args["domain"] as? String,
              let certificate = args["certificate"] as? String
        else {
          await MainActor.run {
            result(
                FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Missing required arguments",
                    details: nil))
          }
          return
        }

        try await TrustPin.verify(domain: domain, certificate: certificate)

        await MainActor.run {
          result(nil)
        }
      } catch let error as TrustPinErrors {
        await MainActor.run {
          result(
              FlutterError(
                  code: mapTrustPinError(error),
                  message: error.localizedDescription,
                  details: nil))
        }
      } catch {
        await MainActor.run {
          result(
              FlutterError(
                  code: "VERIFY_ERROR",
                  message: error.localizedDescription,
                  details: nil))
        }
      }
    }
  }

  private func handleSetLogLevel(call: FlutterMethodCall, result: @escaping FlutterResult) {
    Task {
      guard let args = call.arguments as? [String: Any],
            let logLevelString = args["logLevel"] as? String
      else {
        await MainActor.run {
          result(
              FlutterError(
                  code: "INVALID_ARGUMENTS",
                  message: "Missing logLevel argument",
                  details: nil))
        }
        return
      }

      let logLevel: TrustPinLogLevel
      switch logLevelString.lowercased() {
      case "none":
        logLevel = .none
      case "error":
        logLevel = .error
      case "info":
        logLevel = .info
      case "debug":
        logLevel = .debug
      default:
        logLevel = .error
      }

      await TrustPin.set(logLevel: logLevel)

      await MainActor.run {
        result(nil)
      }
    }
  }

  private func mapTrustPinError(_ error: TrustPinErrors) -> String {
    switch error {
    case .invalidProjectConfig:
      return "INVALID_PROJECT_CONFIG"
    case .errorFetchingPinningInfo:
      return "ERROR_FETCHING_PINNING_INFO"
    case .invalidServerCert:
      return "INVALID_SERVER_CERT"
    case .pinsMismatch:
      return "PINS_MISMATCH"
    case .allPinsExpired:
      return "ALL_PINS_EXPIRED"
    case .configurationValidationFailed:
      return "CONFIGURATION_VALIDATION_FAILED"
    case .domainNotRegistered:
      return "DOMAIN_NOT_REGISTERED"
    @unknown default:
      return "INVALID_PROJECT_CONFIG"
    }
  }
}
