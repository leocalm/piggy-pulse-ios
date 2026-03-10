import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var profile: ProfileResponse?
    @State private var preferences: PreferencesResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showChangePassword = false
    @State private var showEditProfile = false
    @State private var selectedTheme = "system"
    @State private var selectedDateFormat = "DD/MM/YYYY"
    @State private var selectedNumberFormat = "1,234.56"
    @State private var isSavingPreferences = false
    @State private var preferencesDirty = false
    @State private var notificationsEnabled = true
    @State private var notificationPeriodStarting = true
    @State private var notificationPeriodSummary = true
    @State private var notificationOverlayLifecycle = true

    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: PPSpacing.xl) {
                    if isLoading {
                        HStack { Spacer(); ProgressView().tint(.ppTextSecondary); Spacer() }
                            .padding(.vertical, PPSpacing.xxxl)
                    } else if let error = errorMessage {
                        VStack(spacing: PPSpacing.md) {
                            Image(systemName: "exclamationmark.triangle").font(.system(size: 32)).foregroundColor(.ppAmber)
                            Text(error).font(.ppBody).foregroundColor(.ppTextSecondary)
                            Button("Retry") { Task { await load() } }.font(.ppHeadline).foregroundColor(.ppPrimary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, PPSpacing.xxxl)
                    } else {
                        // Profile card
                        if let p = profile {
                            profileCard(p)
                        }

                        // Security card
                        securityCard

                        // Preferences card
                        preferencesCard

                        // Notifications card
                        notificationsCard

                        // App info
                        appInfoCard
                    }
                }
                .padding(PPSpacing.lg)
            }
            .background(Color.ppBackground)
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordSheet()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showEditProfile, onDismiss: { Task { await load() } }) {
                EditProfileSheet(profile: profile)
                    .environmentObject(appState)
            }
            .task { await load() }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Profile

    private func profileCard(_ p: ProfileResponse) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("PROFILE")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            settingsRow("Name", value: p.name)
            settingsRow("Email", value: p.email)
            settingsRow("Currency", value: currencyDisplay)

            Divider().background(Color.ppBorder)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showEditProfile = true
            } label: {
                HStack {
                    Label("Edit Profile", systemImage: "pencil")
                        .font(.ppBody)
                        .foregroundColor(.ppPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.ppTextTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    // MARK: - Security

    private var securityCard: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("SECURITY")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showChangePassword = true
            } label: {
                HStack {
                    Label("Change Password", systemImage: "key")
                        .font(.ppBody)
                        .foregroundColor(.ppTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.ppTextTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    // MARK: - Preferences

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("PREFERENCES")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            preferenceRow("Theme", selection: $selectedTheme, options: [
                ("system", "System"), ("light", "Light"), ("dark", "Dark")
            ])
            .onChange(of: selectedTheme) { _, _ in preferencesDirty = true }

            preferenceRow("Date Format", selection: $selectedDateFormat, options: [
                ("DD/MM/YYYY", "DD/MM/YYYY"),
                ("MM/DD/YYYY", "MM/DD/YYYY"),
                ("YYYY-MM-DD", "YYYY-MM-DD")
            ])
            .onChange(of: selectedDateFormat) { _, _ in preferencesDirty = true }

            preferenceRow("Number Format", selection: $selectedNumberFormat, options: [
                ("1.234,56", "1.234,56"),
                ("1,234.56", "1,234.56"),
                ("1 234.56", "1 234.56")
            ])
            .onChange(of: selectedNumberFormat) { _, _ in preferencesDirty = true }

            if preferencesDirty {
                Divider().background(Color.ppBorder)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    Task { await savePreferences() }
                } label: {
                    HStack {
                        Label("Save Preferences", systemImage: "checkmark")
                            .font(.ppBody)
                            .foregroundColor(.ppPrimary)
                        Spacer()
                        if isSavingPreferences {
                            ProgressView().tint(.ppTextSecondary)
                        }
                    }
                }
                .disabled(isSavingPreferences)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
        .animation(.easeInOut(duration: 0.2), value: preferencesDirty)
    }

    private func preferenceRow(_ label: LocalizedStringKey, selection: Binding<String>, options: [(String, String)]) -> some View {
        HStack {
            Text(label)
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary)
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.0) { value, display in
                    Text(display).tag(value)
                }
            }
            .pickerStyle(.menu)
            .tint(.ppTextPrimary)
        }
    }

    // MARK: - Notifications

    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("NOTIFICATIONS")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            Toggle(isOn: $notificationsEnabled) {
                Text("Notifications")
                    .font(.ppBody)
                    .foregroundColor(.ppTextPrimary)
            }
            .tint(.ppPrimary)
            .onChange(of: notificationsEnabled) { _, enabled in
                handleNotificationMasterToggle(enabled)
            }

            Divider().background(Color.ppBorder)

            Toggle(isOn: $notificationPeriodStarting) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Period starting")
                        .font(.ppBody)
                        .foregroundColor(.ppTextPrimary)
                    Text("When a new period begins")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                }
            }
            .tint(.ppPrimary)
            .disabled(!notificationsEnabled)
            .onChange(of: notificationPeriodStarting) { _, v in
                var prefs = NotificationPreferences()
                prefs.periodStarting = v
                Task { await appState.scheduleNotifications() }
            }

            Toggle(isOn: $notificationPeriodSummary) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Period summary")
                        .font(.ppBody)
                        .foregroundColor(.ppTextPrimary)
                    Text("When a period ends")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                }
            }
            .tint(.ppPrimary)
            .disabled(!notificationsEnabled)
            .onChange(of: notificationPeriodSummary) { _, v in
                var prefs = NotificationPreferences()
                prefs.periodSummary = v
                Task { await appState.scheduleNotifications() }
            }

            Toggle(isOn: $notificationOverlayLifecycle) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Overlay lifecycle")
                        .font(.ppBody)
                        .foregroundColor(.ppTextPrimary)
                    Text("When an overlay starts or ends")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                }
            }
            .tint(.ppPrimary)
            .disabled(!notificationsEnabled)
            .onChange(of: notificationOverlayLifecycle) { _, v in
                var prefs = NotificationPreferences()
                prefs.overlayLifecycle = v
                Task { await appState.scheduleNotifications() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func handleNotificationMasterToggle(_ enabled: Bool) {
        var prefs = NotificationPreferences()
        prefs.isEnabled = enabled
        if enabled {
            Task {
                try? await appState.notificationScheduler.requestAuthorization()
                // Check actual system authorization after requesting
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                if settings.authorizationStatus == .denied {
                    // System blocked — snap toggle back to off
                    var p = NotificationPreferences()
                    p.isEnabled = false
                    notificationsEnabled = false
                } else {
                    // Re-sync sub-toggles from UserDefaults in case they changed
                    let p = NotificationPreferences()
                    notificationPeriodStarting = p.periodStarting
                    notificationPeriodSummary = p.periodSummary
                    notificationOverlayLifecycle = p.overlayLifecycle
                    await appState.scheduleNotifications()
                }
            }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }

    // MARK: - App Info

    private var appInfoCard: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("APP")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            settingsRow("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            settingsRow("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    private var currencyDisplay: String {
        let code = appState.currencyCode
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = code
        let symbol = fmt.currencySymbol ?? code
        let name = Locale.current.localizedString(forCurrencyCode: code) ?? code
        return "\(symbol) \(name)"
    }

    // MARK: - Helpers

    private func settingsRow(_ label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary)
            Spacer()
            Text(value)
                .font(.ppBody)
                .foregroundColor(.ppTextPrimary)
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let profileTask: ProfileResponse = appState.apiClient.request(.profile)
            async let prefsTask: PreferencesResponse = appState.apiClient.request(.preferences)
            let (p, pr) = try await (profileTask, prefsTask)
            profile = p
            preferences = pr
            selectedTheme = pr.theme == "auto" ? "system" : pr.theme
            selectedDateFormat = pr.dateFormat
            selectedNumberFormat = pr.numberFormat
            let prefs = NotificationPreferences()
            notificationsEnabled = prefs.isEnabled
            notificationPeriodStarting = prefs.periodStarting
            notificationPeriodSummary = prefs.periodSummary
            notificationOverlayLifecycle = prefs.overlayLifecycle
        } catch {
            errorMessage = String(localized: "Failed to load settings.")
        }
        isLoading = false
    }

    private func savePreferences() async {
        isSavingPreferences = true
        struct Req: Encodable {
            let theme: String
            let dateFormat: String
            let numberFormat: String
            let compactMode: Bool
        }
        let themeValue = selectedTheme == "system" ? "auto" : selectedTheme
        let req = Req(theme: themeValue, dateFormat: selectedDateFormat, numberFormat: selectedNumberFormat, compactMode: false)
        do {
            let updated: PreferencesResponse = try await appState.apiClient.request(.updatePreferences, body: req)
            preferences = updated
            preferencesDirty = false
            appState.applyTheme(themeValue)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isSavingPreferences = false
    }
}
