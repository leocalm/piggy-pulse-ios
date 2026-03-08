import SwiftUI

struct CreatePeriodSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // Period Setup
    @State private var startDate = Date()
    @State private var duration = 1
    @State private var durationUnit: DurationUnitOption = .months

    // End Rule
    @State private var endRuleMode: EndRuleMode = .byDuration
    @State private var manualEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()

    // Naming
    @State private var name = ""

    // State
    @State private var isLoading = false
    @State private var errorMessage: String?

    var onCreated: () -> Void

    // MARK: - Computed

    private var calculatedEndDate: Date {
        let cal = Calendar.current
        switch durationUnit {
        case .days:
            return cal.date(byAdding: .day, value: duration, to: startDate) ?? startDate
        case .weeks:
            return cal.date(byAdding: .day, value: duration * 7, to: startDate) ?? startDate
        case .months:
            return cal.date(byAdding: .month, value: duration, to: startDate) ?? startDate
        }
    }

    private var effectiveEndDate: Date {
        endRuleMode == .byDuration ? calculatedEndDate : manualEndDate
    }

    private var isDisabled: Bool {
        name.trimmingCharacters(in: .whitespaces).count < 3 ||
        effectiveEndDate <= startDate ||
        isLoading
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: PPSpacing.xl) {
                        // Error
                        if let error = errorMessage {
                            Text(error)
                                .font(.ppCallout)
                                .foregroundColor(.ppDestructive)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Period Setup section
                        periodSetupSection

                        // End Rule section
                        endRuleSection

                        // Naming section
                        namingSection
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle("Create Budget Period")
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
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await createPeriod() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                        }
                    }
                    .foregroundColor(.ppTextSecondary)
                    .disabled(isDisabled || isLoading)
                    .opacity(isDisabled ? 0.6 : 1)
                }
            }
        }
    }

    // MARK: - Period Setup

    private var periodSetupSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            VStack(alignment: .leading, spacing: PPSpacing.xs) {
                Text("Period Setup")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)
                Text("Period boundaries are structural and can reclassify transactions.")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }

            // Start Date
            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                HStack(spacing: 2) {
                    Text("Start Date")
                        .font(.ppCallout)
                        .fontWeight(.semibold)
                        .foregroundColor(.ppTextPrimary)
                    Text("*")
                        .font(.ppCallout)
                        .foregroundColor(.ppDestructive)
                }

                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(.ppPrimary)
            }

            // Duration (only visible in duration mode)
            if endRuleMode == .byDuration {
                HStack(spacing: PPSpacing.md) {
                    // Duration value
                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        HStack(spacing: 2) {
                            Text("Duration")
                                .font(.ppCallout)
                                .fontWeight(.semibold)
                                .foregroundColor(.ppTextPrimary)
                            Text("*")
                                .font(.ppCallout)
                                .foregroundColor(.ppDestructive)
                        }

                        HStack {
                            TextField("1", value: $duration, format: .number)
                                .keyboardType(.numberPad)
                                .font(.ppBody)
                                .foregroundColor(.ppTextPrimary)

                            Stepper("", value: $duration, in: 1...365)
                                .labelsHidden()
                                .tint(.ppPrimary)
                        }
                        .padding(.horizontal, PPSpacing.lg)
                        .padding(.vertical, PPSpacing.sm)
                        .background(Color.ppSurface)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: PPRadius.md)
                                .stroke(Color.ppBorder, lineWidth: 1)
                        )
                    }

                    // Duration unit
                    VStack(alignment: .leading, spacing: PPSpacing.sm) {
                        Text("Duration Unit")
                            .font(.ppCallout)
                            .fontWeight(.semibold)
                            .foregroundColor(.ppTextPrimary)

                        Picker("Duration Unit", selection: $durationUnit) {
                            ForEach(DurationUnitOption.allCases, id: \.self) { unit in
                                Text(unit.label).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.ppPrimary)
                    }
                }
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
    }

    // MARK: - End Rule

    private var endRuleSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("End Rule")
                .font(.ppTitle3)
                .foregroundColor(.ppTextPrimary)

            Picker("End Rule", selection: $endRuleMode) {
                Text("By Duration").tag(EndRuleMode.byDuration)
                Text("Set Manually").tag(EndRuleMode.manual)
            }
            .pickerStyle(.segmented)

            if endRuleMode == .byDuration {
                // Calculated end date display
                VStack(alignment: .leading, spacing: PPSpacing.xs) {
                    Text("Calculated End Date")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                    Text(formatDate(calculatedEndDate))
                        .font(.ppHeadline)
                        .foregroundColor(.ppTextPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PPSpacing.lg)
                .background(Color.ppSurface)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
            } else {
                // Manual end date picker
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    HStack(spacing: 2) {
                        Text("Manual End Date")
                            .font(.ppCallout)
                            .fontWeight(.semibold)
                            .foregroundColor(.ppTextPrimary)
                        Text("*")
                            .font(.ppCallout)
                            .foregroundColor(.ppDestructive)
                    }

                    DatePicker("", selection: $manualEndDate, in: startDate..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(.ppPrimary)
                }
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
    }

    // MARK: - Naming

    private var namingSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text("Naming")
                .font(.ppTitle3)
                .foregroundColor(.ppTextPrimary)

            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                HStack(spacing: 2) {
                    Text("Period Name").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                }
                TextField("e.g. March 2026", text: $name)
                    .font(.ppBody).foregroundColor(.ppTextPrimary)
                    .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                    .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
    }

    // MARK: - Create

    private func createPeriod() async {
        isLoading = true
        errorMessage = nil

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        struct CreateRequest: Encodable {
            let name: String
            let startDate: String
            let endDate: String
        }

        let request = CreateRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            startDate: fmt.string(from: startDate),
            endDate: fmt.string(from: effectiveEndDate)
        )

        do {
            let _ = try await appState.apiClient.requestString(.createPeriod, body: request)
            onCreated()
            dismiss()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = String(localized: "Failed to create period.")
        }

        isLoading = false
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .long
        return fmt.string(from: date)
    }
}

// MARK: - Supporting Types

enum EndRuleMode {
    case byDuration, manual
}

enum DurationUnitOption: String, CaseIterable {
    case days, weeks, months

    var label: String {
        switch self {
        case .days: return "Days"
        case .weeks: return "Weeks"
        case .months: return "Months"
        }
    }
}
