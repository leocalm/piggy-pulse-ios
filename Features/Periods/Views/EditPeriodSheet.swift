import SwiftUI

struct EditPeriodSheet: View {
    let period: BudgetPeriod
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var theme

    @State private var name: String
    @State private var startDate: Date
    @State private var duration: Int
    @State private var durationUnit: DurationUnitOption

    @State private var isLoading = false
    @State private var errorMessage: String?

    init(period: BudgetPeriod) {
        self.period = period
        self._name = State(initialValue: period.name)
        self._startDate = State(initialValue: period.startDateFormatted ?? Date())
        self._duration = State(initialValue: max(period.length, 1))

        let unit: DurationUnitOption
        if period.length >= 28 && period.length % 28 == 0 {
            unit = .months
        } else if period.length >= 7 && period.length % 7 == 0 {
            unit = .weeks
        } else {
            unit = .days
        }
        self._durationUnit = State(initialValue: unit)
    }

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

    private var isDisabled: Bool {
        name.trimmingCharacters(in: .whitespaces).count < 3 ||
        calculatedEndDate <= startDate ||
        isLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ppBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: PPSpacing.xl) {
                        if let error = errorMessage {
                            Text(error)
                                .font(.ppCallout)
                                .foregroundColor(.ppDestructive)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        periodSetupSection
                        namingSection
                    }
                    .padding(PPSpacing.xl)
                }
            }
            .navigationTitle(String(localized: "nav.periods"))
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
                        Task { await updatePeriod() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text(String(localized: "button.saveChanges"))
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isDisabled || isLoading)
                }
            }
        }
    }

    private var periodSetupSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            VStack(alignment: .leading, spacing: PPSpacing.xs) {
                Text(String(localized: "section.periodSetup"))
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)
                Text(String(localized: "createPeriod.boundaryNote"))
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }

            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                HStack(spacing: 2) {
                    Text(String(localized: "field.startDate"))
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
                    .tint(theme.primary)
            }

            HStack(spacing: PPSpacing.md) {
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    HStack(spacing: 2) {
                        Text(String(localized: "field.duration"))
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
                            .tint(theme.primary)
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

                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text(String(localized: "field.durationUnit"))
                        .font(.ppCallout)
                        .fontWeight(.semibold)
                        .foregroundColor(.ppTextPrimary)

                    Picker("Duration Unit", selection: $durationUnit) {
                        ForEach(DurationUnitOption.allCases, id: \.self) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(theme.primary)
                }
            }

            VStack(alignment: .leading, spacing: PPSpacing.xs) {
                Text(String(localized: "field.calculatedEndDate"))
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
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
    }

    private var namingSection: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text(String(localized: "section.naming"))
                .font(.ppTitle3)
                .foregroundColor(.ppTextPrimary)

            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                HStack(spacing: 2) {
                    Text(String(localized: "field.periodName")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
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

    private func updatePeriod() async {
        isLoading = true
        errorMessage = nil

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        let request = UpdatePeriodRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            startDate: fmt.string(from: startDate),
            manualEndDate: fmt.string(from: calculatedEndDate)
        )

        do {
            try await appState.apiClient.request(.updatePeriod(period.id), body: request)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch let error as APIError {
            errorMessage = error.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = String(localized: "Failed to update period.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        isLoading = false
    }

    private func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .long
        return fmt.string(from: date)
    }
}

struct UpdatePeriodRequest: Encodable {
    let name: String
    let startDate: String
    let periodType: String
    let manualEndDate: String

    init(name: String, startDate: String, manualEndDate: String) {
        self.name = name
        self.startDate = startDate
        self.periodType = "ManualEndDate"
        self.manualEndDate = manualEndDate
    }
}
