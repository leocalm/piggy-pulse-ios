import Sentry
import SwiftUI

struct FeedbackSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var theme

    @State private var message = ""
    @State private var name = ""
    @State private var email = ""
    @State private var isSending = false
    @State private var success = false
    @State private var errorMessage: String?

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDisabled: Bool {
        trimmedMessage.isEmpty || isSending
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: PPSpacing.xl) {
                        if success {
                            VStack(spacing: PPSpacing.md) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(theme.tertiary)
                                Text(String(localized: "feedback.success"))
                                    .font(.ppHeadline)
                                    .foregroundColor(.ppTextPrimary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, PPSpacing.xxxl)
                        } else {
                            Text(String(localized: "feedback.subtitle"))
                                .font(.ppBody)
                                .foregroundColor(.ppTextSecondary)

                            if let error = errorMessage {
                                Text(error)
                                    .font(.ppCallout)
                                    .foregroundColor(.ppDestructive)
                            }

                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                HStack(spacing: 2) {
                                    Text(String(localized: "field.message"))
                                        .font(.ppCallout)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.ppTextPrimary)
                                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                                }
                                TextField(
                                    String(localized: "feedback.messagePlaceholder"),
                                    text: $message,
                                    axis: .vertical
                                )
                                .lineLimit(6...12)
                                .font(.ppBody)
                                .foregroundColor(.ppTextPrimary)
                                .padding(.horizontal, PPSpacing.lg)
                                .padding(.vertical, PPSpacing.md)
                                .background(Color.ppSurface)
                                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            }

                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text(String(localized: "field.name"))
                                    .font(.ppCallout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.ppTextPrimary)
                                TextField(String(localized: "field.fullName"), text: $name)
                                    .textContentType(.name)
                                    .font(.ppBody)
                                    .foregroundColor(.ppTextPrimary)
                                    .padding(.horizontal, PPSpacing.lg)
                                    .padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            }

                            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                Text(String(localized: "field.email"))
                                    .font(.ppCallout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.ppTextPrimary)
                                TextField("name@example.com", text: $email)
                                    .textContentType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.emailAddress)
                                    .font(.ppBody)
                                    .foregroundColor(.ppTextPrimary)
                                    .padding(.horizontal, PPSpacing.lg)
                                    .padding(.vertical, PPSpacing.md)
                                    .background(Color.ppSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                            }
                        }
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle(String(localized: "nav.feedback"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .foregroundColor(.ppTextSecondary)
                }
                if !success {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            send()
                        } label: {
                            if isSending {
                                ProgressView()
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                        }
                        .foregroundColor(.ppTextSecondary)
                        .disabled(isDisabled)
                        .opacity(isDisabled ? 0.6 : 1)
                    }
                }
            }
            .onAppear {
                if name.isEmpty { name = appState.currentUser?.name ?? "" }
                if email.isEmpty { email = appState.currentUser?.email ?? "" }
            }
        }
    }

    private func send() {
        isSending = true
        errorMessage = nil

        let feedback = SentryFeedback(
            message: trimmedMessage,
            name: name.isEmpty ? nil : name,
            email: email.isEmpty ? nil : email,
            source: .custom
        )
        SentrySDK.capture(feedback: feedback)

        success = true
        isSending = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            dismiss()
        }
    }
}
