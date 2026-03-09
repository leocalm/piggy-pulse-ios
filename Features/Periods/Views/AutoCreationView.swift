import SwiftUI

struct AutoCreationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var schedule: PeriodSchedule?
    @State private var isLoading = true
    @State private var isDisabled = false
    @State private var errorMessage: String?

    // Edit fields
    @State private var startDay = 1
    @State private var durationValue = 1
    @State private var durationUnit = "months"
    @State private var saturdayAdj = "keep"
    @State private var sundayAdj = "keep"
    @State private var namePattern = "{month} {year}"
    @State private var generateAhead = 3
    @State private var isSaving = false
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView().tint(.ppTextSecondary(colorScheme))
                        Spacer()
                    }
                    .padding(.vertical, PPSpacing.xxxl)
                } else if isDisabled {
                    disabledState
                } else {
                    scheduleForm
                }
            }
            .padding(PPSpacing.lg)
        }
        .background(Color.ppBackground(colorScheme))
        .navigationTitle("Auto-Creation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.ppBackground(colorScheme), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await loadSchedule()
        }
    }

    // MARK: - Disabled State

    private var disabledState: some View {
        VStack(spacing: PPSpacing.xl) {
            VStack(spacing: PPSpacing.md) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 40))
                    .foregroundColor(.ppTextTertiary(colorScheme))

                Text("Auto-Creation is disabled")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary(colorScheme))

                Text("Enable a schedule to generate future periods automatically.")
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary(colorScheme))
                    .multilineTextAlignment(.center)
            }

            Button {
                isDisabled = false
                isEditing = true
            } label: {
                Label("Set up Auto-Creation", systemImage: "arrow.triangle.2.circlepath")
                    .font(.ppHeadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PPSpacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(.ppPrimary)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
        }
        .padding(PPSpacing.xl)
        .background(Color.ppCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder(colorScheme), lineWidth: 1)
        )
    }

    // MARK: - Schedule Form

    private var scheduleForm: some View {
        VStack(spacing: PPSpacing.xl) {
            if let error = errorMessage {
                Text(error)
                    .font(.ppCallout)
                    .foregroundColor(.ppDestructive)
                    .multilineTextAlignment(.center)
            }

            // Period Setup
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                Text("Period Setup")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary(colorScheme))

                // Start Day
                HStack {
                    Text("Start Day of Month")
                        .font(.ppCallout)
                        .foregroundColor(.ppTextSecondary(colorScheme))
                    Spacer()
                    Picker("", selection: $startDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    .tint(.ppPrimary)
                }

                // Duration
                HStack {
                    Text("Duration")
                        .font(.ppCallout)
                        .foregroundColor(.ppTextSecondary(colorScheme))
                    Spacer()
                    HStack(spacing: PPSpacing.sm) {
                        TextField("1", value: $durationValue, format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 50)
                            .multilineTextAlignment(.trailing)
                            .font(.ppBody)
                            .foregroundColor(.ppTextPrimary(colorScheme))

                        Picker("", selection: $durationUnit) {
                            Text("Days").tag("days")
                            Text("Weeks").tag("weeks")
                            Text("Months").tag("months")
                        }
                        .tint(.ppPrimary)
                    }
                }

                // Generate Ahead
                HStack {
                    Text("Generate Ahead")
                        .font(.ppCallout)
                        .foregroundColor(.ppTextSecondary(colorScheme))
                    Spacer()
                    Stepper("\(generateAhead) periods", value: $generateAhead, in: 0...12)
                        .font(.ppCallout)
                        .foregroundColor(.ppTextPrimary(colorScheme))
                }
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: PPRadius.lg)
                    .stroke(Color.ppBorder(colorScheme), lineWidth: 1)
            )

            // Weekend Adjustments
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                Text("Weekend Adjustments")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary(colorScheme))

                weekendRow("Saturday", selection: $saturdayAdj)
                weekendRow("Sunday", selection: $sundayAdj)
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: PPRadius.lg)
                    .stroke(Color.ppBorder(colorScheme), lineWidth: 1)
            )

            // Naming
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                Text("Naming")
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary(colorScheme))

                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    HStack(spacing: 2) {
                        Text("Name Pattern").font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                    }
                    TextField("{month} {year}", text: $namePattern)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .font(.ppBody).foregroundColor(.ppTextPrimary(colorScheme))
                        .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                        .background(Color.ppSurface(colorScheme)).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
                }

                Text("Use {month} and {year} as placeholders.")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextTertiary(colorScheme))
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: PPRadius.lg)
                    .stroke(Color.ppBorder(colorScheme), lineWidth: 1)
            )

            // Actions
            VStack(spacing: PPSpacing.md) {
                Button {
                    Task { await saveSchedule() }
                } label: {
                    Group {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text(schedule == nil ? "Enable Auto-Creation" : "Save Changes")
                                .font(.ppHeadline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PPSpacing.md)
                }
                .buttonStyle(.borderedProminent)
                .tint(.ppPrimary)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
                .disabled(isSaving || namePattern.trimmingCharacters(in: .whitespaces).isEmpty)

                if schedule != nil {
                    Button(role: .destructive) {
                        Task { await deleteSchedule() }
                    } label: {
                        Text("Disable Auto-Creation")
                            .font(.ppCallout)
                            .foregroundColor(.ppDestructive)
                    }
                }
            }
        }
    }

    // MARK: - Weekend Row

    private func weekendRow(_ day: String, selection: Binding<String>) -> some View {
        HStack {
            Text("If \(day)")
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary(colorScheme))
            Spacer()
            Picker("", selection: selection) {
                Text("Keep").tag("keep")
                Text("Move to Friday").tag("friday")
                Text("Move to Monday").tag("monday")
            }
            .tint(.ppPrimary)
        }
    }

    // MARK: - API

    private func loadSchedule() async {
        isLoading = true
        do {
            let s: PeriodSchedule = try await appState.apiClient.request(.schedule)
            schedule = s
            startDay = s.startDay
            durationValue = s.durationValue
            durationUnit = s.durationUnit
            saturdayAdj = s.saturdayAdjustment
            sundayAdj = s.sundayAdjustment
            namePattern = s.namePattern
            generateAhead = s.generateAhead
            isDisabled = false
        } catch {
            // 404 means no schedule — show disabled state
            isDisabled = true
        }
        isLoading = false
    }

    private func saveSchedule() async {
        isSaving = true
        errorMessage = nil

        struct ScheduleRequest: Encodable {
            let startDay: Int
            let durationValue: Int
            let durationUnit: String
            let saturdayAdjustment: String
            let sundayAdjustment: String
            let namePattern: String
            let generateAhead: Int
        }

        let request = ScheduleRequest(
            startDay: startDay,
            durationValue: durationValue,
            durationUnit: durationUnit,
            saturdayAdjustment: saturdayAdj,
            sundayAdjustment: sundayAdj,
            namePattern: namePattern.trimmingCharacters(in: .whitespaces),
            generateAhead: generateAhead
        )

        do {
            let endpoint: APIEndpoint = schedule == nil ? .createSchedule : .updateSchedule
            let s: PeriodSchedule = try await appState.apiClient.request(endpoint, body: request)
            schedule = s
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch let error as APIError {
            errorMessage = error.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = String(localized: "Failed to save schedule.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        isSaving = false
    }

    private func deleteSchedule() async {
        isSaving = true
        errorMessage = nil

        do {
            try await appState.apiClient.request(.deleteSchedule)
            schedule = nil
            isDisabled = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = String(localized: "Failed to disable auto-creation.")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        isSaving = false
    }
}
