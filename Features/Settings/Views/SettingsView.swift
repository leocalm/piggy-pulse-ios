import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var profile: ProfileResponse?
    @State private var preferences: PreferencesResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showChangePassword = false
    @State private var showEditProfile = false

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
                        if let prefs = preferences {
                            preferencesCard(prefs)
                        }
                        
                        // App info
                        appInfoCard
                    }
                }
                .padding(PPSpacing.lg)
            }
            .background(Color.ppBackground)
            .toolbarBackground(Color.ppBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
            HStack {
                Text("PROFILE")
                    .font(.ppOverline)
                    .foregroundColor(.ppTextSecondary)
                    .tracking(1)
                Spacer()
                Button {
                    showEditProfile = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.ppCaption)
                        .foregroundColor(.ppPrimary)
                        .padding(.horizontal, PPSpacing.md)
                        .padding(.vertical, PPSpacing.sm)
                        .background(Color.ppPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
                }
            }

            settingsRow("Name", value: p.name)
            settingsRow("Email", value: p.email)
            settingsRow("Timezone", value: p.timezone)
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

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Password")
                        .font(.ppCallout)
                        .foregroundColor(.ppTextSecondary)
                    Text("••••••••")
                        .font(.ppBody)
                        .foregroundColor(.ppTextPrimary)
                }
                Spacer()
                Button {
                    showChangePassword = true
                } label: {
                    Label("Change", systemImage: "key")
                        .font(.ppCaption)
                        .foregroundColor(.ppPrimary)
                        .padding(.horizontal, PPSpacing.md)
                        .padding(.vertical, PPSpacing.sm)
                        .background(Color.ppPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
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

    private func preferencesCard(_ prefs: PreferencesResponse) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("PREFERENCES")
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            settingsRow("Theme", value: prefs.theme.capitalized)
            settingsRow("Date Format", value: prefs.dateFormat)
            settingsRow("Number Format", value: prefs.numberFormat)
            settingsRow("Compact Mode", value: prefs.compactMode ? "On" : "Off")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
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
        } catch {
            errorMessage = "Failed to load settings."
        }
        isLoading = false
    }
}
