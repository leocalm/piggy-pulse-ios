import Foundation
import Sentry

enum SentryService {
    static func start() {
        guard let dsn = Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String,
              !dsn.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = currentEnvironment
            options.releaseName = currentRelease
            options.enableAutoPerformanceTracing = true
            options.tracesSampleRate = 0.2
            #if DEBUG
            options.debug = true
            #endif
        }
    }

    private static var currentEnvironment: String {
        #if DEBUG
        return "debug"
        #elseif STAGING
        return "staging"
        #else
        return "production"
        #endif
    }

    private static var currentRelease: String? {
        let info = Bundle.main.infoDictionary
        guard let version = info?["CFBundleShortVersionString"] as? String,
              let build = info?["CFBundleVersion"] as? String,
              let bundleId = info?["CFBundleIdentifier"] as? String else {
            return nil
        }
        return "\(bundleId)@\(version)+\(build)"
    }
}
