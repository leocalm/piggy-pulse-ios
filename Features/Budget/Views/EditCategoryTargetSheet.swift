import SwiftUI

struct EditCategoryTargetSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let target: CategoryTarget
    let detail: CategoryListItem?
    var onSave: (Int32) async -> Void
    var onExclude: () async -> Void
    var onInclude: () async -> Void

    @State private var amountText: String = ""
    @State private var isLoading = false

    private var parsedCents: Int32? {
        guard let value = Double(amountText.replacingOccurrences(of: ",", with: ".")) else { return nil }
        return Int32(value * 100)
    }

    private var isSaveDisabled: Bool {
        parsedCents == nil || parsedCents! <= 0 || isLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground.ignoresSafeArea()
                VStack(spacing: PPSpacing.xl) {
                    // Header
                    HStack(spacing: PPSpacing.md) {
                        Text(detail?.icon ?? "📂")
                            .font(.system(size: 32))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(target.categoryName)
                                .font(.ppTitle)
                                .foregroundColor(.ppTextPrimary)
                            if target.excluded {
                                Text("Currently excluded")
                                    .font(.ppCaption)
                                    .foregroundColor(.ppAmber)
                            }
                        }
                        Spacer()
                    }
                    .padding(PPSpacing.xl)
                    .background(Color.ppCard)
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

                    // Amount input
                    if !target.excluded {
                        VStack(alignment: .leading, spacing: PPSpacing.sm) {
                            Text("TARGET AMOUNT")
                                .font(.ppOverline)
                                .foregroundColor(.ppTextSecondary)
                                .tracking(1)

                            HStack {
                                Text(appState.currencyCode)
                                    .font(.ppCallout)
                                    .foregroundColor(.ppTextTertiary)
                                    .frame(width: 40)
                                TextField("0.00", text: $amountText)
                                    .font(.ppAmount)
                                    .foregroundColor(.ppTextPrimary)
                                    .keyboardType(.decimalPad)
                            }
                            .padding(PPSpacing.lg)
                            .background(Color.ppSurface)
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                        }
                    }

                    Spacer()

                    // Action buttons
                    VStack(spacing: PPSpacing.md) {
                        if !target.excluded {
                            Button {
                                guard let cents = parsedCents else { return }
                                Task {
                                    isLoading = true
                                    await onSave(cents)
                                    isLoading = false
                                    dismiss()
                                }
                            } label: {
                                Group {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Save Target")
                                            .font(.ppHeadline)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, PPSpacing.lg)
                                .background(isSaveDisabled ? Color.ppPrimary.opacity(0.4) : Color.ppPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            }
                            .disabled(isSaveDisabled)

                            Button {
                                Task {
                                    isLoading = true
                                    await onExclude()
                                    isLoading = false
                                    dismiss()
                                }
                            } label: {
                                Text("Exclude from budget")
                                    .font(.ppCallout)
                                    .foregroundColor(.ppAmber)
                            }
                            .disabled(isLoading)
                        } else {
                            Button {
                                Task {
                                    isLoading = true
                                    await onInclude()
                                    isLoading = false
                                    dismiss()
                                }
                            } label: {
                                Text("Re-include in budget")
                                    .font(.ppHeadline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, PPSpacing.lg)
                                    .background(Color.ppCyan)
                                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            }
                            .disabled(isLoading)
                        }
                    }
                }
                .padding(PPSpacing.xl)
            }
            .navigationTitle("Set Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ppBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(.ppTextSecondary)
                }
            }
            .onAppear {
                if target.targetValue > 0 {
                    let amount = Double(target.targetValue) / 100.0
                    amountText = String(format: "%.2f", amount)
                }
            }
        }
    }
}
