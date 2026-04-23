import SwiftUI

@main
struct PiggyPulseWatchApp: App {

    init() {
        WatchConnectivityManager.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            EncryptionUnavailableView()
        }
    }
}

// MARK: - Encryption Unavailable View

struct EncryptionUnavailableView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("Use iPhone App")
                .font(.headline)

            Text("PiggyPulse now uses end-to-end encryption. Watch support will return in a future update.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
