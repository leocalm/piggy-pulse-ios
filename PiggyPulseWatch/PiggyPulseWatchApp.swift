import SwiftUI
import WatchConnectivity

@main
struct PiggyPulseWatchApp: App {

    @StateObject private var connectivity = WatchConnectivityManager.shared
    @State private var currentPeriod: WatchLoadingState<WatchCurrentPeriod> = .idle
    @State private var netPosition: WatchLoadingState<WatchNetPosition> = .idle
    @State private var accounts: WatchLoadingState<[WatchAccountSummary]> = .idle

    private let accentColor = Color(red: 139.0/255, green: 126.0/255, blue: 200.0/255) // #8B7EC8

    var body: some Scene {
        WindowGroup {
            if connectivity.isAuthenticated {
                TabView {
                    CurrentPeriodView(state: currentPeriod)
                    NetPositionView(state: netPosition)
                    AccountsListView(state: accounts)
                }
                .tabViewStyle(.verticalPage)
                .tint(accentColor)
                .task {
                    await loadAllData()
                }
            } else {
                NotAuthenticatedView()
            }
        }
    }

    // MARK: - Data Loading

    private func loadAllData() async {
        currentPeriod = .loading
        netPosition = .loading
        accounts = .loading

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await loadCurrentPeriod()
            }
            group.addTask {
                await loadNetPosition()
            }
            group.addTask {
                await loadAccounts()
            }
        }
    }

    private func loadCurrentPeriod() async {
        do {
            let data = try await WatchAPIClient.shared.fetchCurrentPeriod()
            currentPeriod = .loaded(data)
        } catch {
            currentPeriod = .error(error.localizedDescription)
        }
    }

    private func loadNetPosition() async {
        do {
            let data = try await WatchAPIClient.shared.fetchNetPosition()
            netPosition = .loaded(data)
        } catch {
            netPosition = .error(error.localizedDescription)
        }
    }

    private func loadAccounts() async {
        do {
            let data = try await WatchAPIClient.shared.fetchAccounts()
            accounts = .loaded(data)
        } catch {
            accounts = .error(error.localizedDescription)
        }
    }
}

// MARK: - Not Authenticated View

struct NotAuthenticatedView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("Sign In Required")
                .font(.headline)

            Text("Open PiggyPulse on your iPhone to sign in.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
