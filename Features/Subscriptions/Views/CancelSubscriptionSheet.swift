import SwiftUI

struct CancelSubscriptionSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let subscription: Subscription
    let apiClient: APIClient
    var onCancelled: () -> Void

    @State private var cancellationDate = Date()
    @State private var isLoading = false
    @State private var errorMessage: String?

    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt
    }()

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
                            Text(String(localized: "subscription.cancel.title"))
                                .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                            // Subscription info
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                HStack {
                                    Text(subscription.name)
                                        .font(.ppHeadline).foregroundColor(.ppTextPrimary)
                                    Spacer()
                                    Text(formatCurrency(subscription.billingAmount, code: appState.currencyCode))
                                        .font(.ppHeadline).foregroundColor(.ppTextPrimary)
                                }
                                Text(subscription.billingCycle.displayName)
                                    .font(.ppCaption).foregroundColor(.ppTextSecondary)
                            }
                            .padding(PPSpacing.lg)
                            .background(Color.ppSurface)
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))

                            // Cancellation date
                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text(String(localized: "subscription.cancel.dateLabel"))
                                    .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                                DatePicker(
                                    String(localized: "subscription.cancel.dateLabel"),
                                    selection: $cancellationDate,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .font(.ppBody)
                                .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                                .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            }

                            Text(String(localized: "subscription.cancel.hint"))
                                .font(.ppCaption).foregroundColor(.ppTextTertiary)
                        }
                        .padding(PPSpacing.lg).background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                        // Buttons
                        VStack(spacing: PPSpacing.md) {
                            Button {
                                Task { await confirmCancel() }
                            } label: {
                                HStack {
                                    Spacer()
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text(String(localized: "subscription.cancel.confirm"))
                                            .font(.ppHeadline)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, PPSpacing.md)
                                .background(Color.ppAmber)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            }
                            .disabled(isLoading)

                            Button {
                                dismiss()
                            } label: {
                                HStack {
                                    Spacer()
                                    Text(String(localized: "subscription.cancel.keep"))
                                        .font(.ppHeadline)
                                    Spacer()
                                }
                                .padding(.vertical, PPSpacing.md)
                                .background(Color.ppSurface)
                                .foregroundColor(.ppTextPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            }
                        }
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle(String(localized: "subscription.cancel.navTitle")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(.ppTextSecondary)
                }
            }
        }
    }

    private func confirmCancel() async {
        isLoading = true; errorMessage = nil

        let req = CancelSubscriptionRequest(cancellationDate: Self.dateFormatter.string(from: cancellationDate))

        do {
            let _: Subscription = try await apiClient.request(.cancelSubscription(subscription.id), body: req)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onCancelled(); dismiss()
        } catch let e as APIError {
            errorMessage = e.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = String(localized: "subscription.cancelError")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        isLoading = false
    }
}
