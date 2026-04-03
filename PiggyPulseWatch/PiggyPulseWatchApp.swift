import SwiftUI

@main
struct PiggyPulseWatchApp: App {

    @StateObject private var connectivity = WatchConnectivityManager.shared
    @State private var currentPeriod: WatchLoadingState<WatchCurrentPeriod> = .idle
    @State private var netPosition: WatchLoadingState<WatchNetPosition> = .idle
    @State private var accounts: WatchLoadingState<[WatchAccountSummary]> = .idle

    private let accentColor = WatchDesign.accentColor

    init() {
        WatchConnectivityManager.shared.activate()
    }

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

        // First fetch periods to find the active one
        let activePeriodId: UUID?
        do {
            let periods = try await WatchAPIClient.shared.fetchPeriods()
            activePeriodId = periods.first(where: { $0.status == "active" })?.id ?? periods.first?.id
        } catch {
            currentPeriod = .error(error.localizedDescription)
            netPosition = .error(error.localizedDescription)
            accounts = .error(error.localizedDescription)
            return
        }

        guard let periodId = activePeriodId else {
            currentPeriod = .error("No active period")
            netPosition = .error("No active period")
            return
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await loadCurrentPeriod(periodId: periodId)
            }
            group.addTask {
                await loadNetPosition(periodId: periodId)
            }
            group.addTask {
                await loadAccounts()
            }
        }
    }

    private func loadCurrentPeriod(periodId: UUID) async {
        do {
            let data = try await WatchAPIClient.shared.fetchCurrentPeriod(periodId: periodId)
            currentPeriod = .loaded(data)
        } catch {
            currentPeriod = .error(error.localizedDescription)
        }
    }

    private func loadNetPosition(periodId: UUID) async {
        do {
            let data = try await WatchAPIClient.shared.fetchNetPosition(periodId: periodId)
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
    @State private var autoRetryTimer: Timer?

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
        .onAppear {
            // Auto-retry token sync every 3 seconds
            WatchConnectivityManager.shared.requestTokenFromPhone()
            autoRetryTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                WatchConnectivityManager.shared.requestTokenFromPhone()
            }
        }
        .onDisappear {
            autoRetryTimer?.invalidate()
        }
    }
}
