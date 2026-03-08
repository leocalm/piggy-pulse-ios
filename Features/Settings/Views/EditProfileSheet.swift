import SwiftUI

struct EditProfileSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let profile: ProfileResponse?

    @State private var name = ""
    @State private var timezone = ""
    @State private var selectedCurrencyId: UUID? = nil
    @State private var currencies: [Currency] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var isDisabled: Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty || timezone.isEmpty || isLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: PPSpacing.xl) {
                        if let error = errorMessage {
                            Text(error).font(.ppCallout).foregroundColor(.ppDestructive).multilineTextAlignment(.center)
                        }

                        VStack(alignment: .leading, spacing: PPSpacing.lg) {
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                HStack(spacing: 2) {
                                    Text("Name").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                }
                                TextField("Your name", text: $name)
                                    .textContentType(.name)
                                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            }

                            // Email (read-only)
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text("Email")
                                    .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                Text(profile?.email ?? "")
                                    .font(.ppBody)
                                    .foregroundColor(.ppTextTertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, PPSpacing.lg)
                                    .padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            }

                            // Currency picker
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                HStack(spacing: 2) {
                                    Text("Timezone").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                }
                                TextField("e.g. Europe/Amsterdam", text: $timezone)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            }

                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text("Default Currency")
                                    .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                if currencies.isEmpty {
                                    HStack { Spacer(); ProgressView().tint(.ppTextSecondary); Spacer() }
                                        .padding(.vertical, PPSpacing.sm)
                                } else {
                                    Picker("Currency", selection: $selectedCurrencyId) {
                                        Text("None").tag(UUID?.none)
                                        ForEach(currencies) { c in
                                            Text("\(c.symbol) \(c.name)").tag(UUID?.some(c.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.ppTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                                }
                            }
                        }
                        .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle("Edit Profile").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .foregroundColor(.ppTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isLoading { ProgressView() } else { Image(systemName: "checkmark") }
                    }
                    .foregroundColor(.ppTextSecondary)
                    .disabled(isDisabled || isLoading)
                    .opacity(isDisabled ? 0.6 : 1)
                }
            }
            .task {
                name = profile?.name ?? ""
                timezone = profile?.timezone ?? ""
                selectedCurrencyId = profile?.defaultCurrencyId
                await loadCurrencies()
            }
        }
    }

    private func loadCurrencies() async {
        do {
            currencies = try await appState.apiClient.request(.currencies)
        } catch {}
    }

    private func save() async {
        isLoading = true; errorMessage = nil

        struct Req: Encodable {
            let name: String
            let timezone: String
            let defaultCurrencyId: UUID?
        }

        let req = Req(name: name.trimmingCharacters(in: .whitespaces), timezone: timezone, defaultCurrencyId: selectedCurrencyId)
        do {
            let _: ProfileResponse = try await appState.apiClient.request(.updateProfile, body: req)
            await appState.loadUserCurrency()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch let e as APIError {
            errorMessage = e.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = String(localized: "Failed to update profile.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isLoading = false
    }
}
