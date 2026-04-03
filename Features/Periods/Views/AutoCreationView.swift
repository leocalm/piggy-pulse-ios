import SwiftUI

struct AutoCreationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var theme
    @State private var schedule: PeriodSchedule?
    @State private var isLoading = true
    @State private var isDisabled = false
    @State private var errorMessage: String?

    // Edit fields
    @State private var recurrenceMethod = "dayOfMonth"
    @State private var startDay = 1
    @State private var durationValue = 1
    @State private var durationUnit = "months"
    @State private var saturdayAdj = "keep"
    @State private var sundayAdj = "keep"
    @State private var namePattern = "{MONTH} {YEAR}"
    @State private var generateAhead = 3
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView().tint(.ppTextSecondary)
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
        .background(Color.ppBackground)
        .navigationTitle(String(localized: "nav.autoCreation"))
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
                    .foregroundColor(.ppTextTertiary)

                Text(String(localized: "autoCreation.disabled"))
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                Text(String(localized: "autoCreation.enableDesc"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                isDisabled = false
            } label: {
                Label(String(localized: "button.setupAutoCreation"), systemImage: "arrow.triangle.2.circlepath")
                    .font(.ppHeadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PPSpacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.primary)
            .buttonBorderShape(.capsule)
        }
        .padding(PPSpacing.xl)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder, lineWidth: 1)
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

            // Recurrence Method
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                Text(String(localized: "autoCreation.recurrenceMethod").uppercased())
                    .font(.ppOverline).foregroundColor(.ppTextSecondary).tracking(1)

                recurrenceOption("dayOfMonth",
                    title: String(localized: "autoCreation.dayOfMonth"),
                    desc: String(localized: "autoCreation.dayOfMonth.desc"))
                recurrenceOption("businessDay",
                    title: String(localized: "autoCreation.businessDay"),
                    desc: String(localized: "autoCreation.businessDay.desc"))
                recurrenceOption("dayOfWeek",
                    title: String(localized: "autoCreation.dayOfWeek"),
                    desc: String(localized: "autoCreation.dayOfWeek.desc"))
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

            // Period Setup
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                Text(String(localized: "section.periodSetup"))
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                // Start Day
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text(String(localized: "field.startDayOfMonth"))
                        .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    Text(String(localized: "field.startDayOfMonth.desc"))
                        .font(.ppCaption).foregroundColor(.ppTextTertiary)
                    Picker("", selection: $startDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    .tint(theme.primary)
                }

                // Duration
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text(String(localized: "field.duration"))
                        .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    HStack(spacing: PPSpacing.sm) {
                        TextField("1", value: $durationValue, format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .font(.ppBody).foregroundColor(.ppTextPrimary)
                            .padding(.horizontal, PPSpacing.md).padding(.vertical, PPSpacing.sm)
                            .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))

                        Picker("", selection: $durationUnit) {
                            Text(String(localized: "unit.days")).tag("days")
                            Text(String(localized: "unit.weeks")).tag("weeks")
                            Text(String(localized: "unit.months")).tag("months")
                        }
                        .tint(theme.primary)
                    }
                }

                // Generate Ahead
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text(String(localized: "field.generateAhead"))
                        .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    Text(String(localized: "field.generateAhead.desc"))
                        .font(.ppCaption).foregroundColor(.ppTextTertiary)
                    Stepper("\(generateAhead)", value: $generateAhead, in: 0...12)
                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                }
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

            // Weekend Adjustments
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                Text(String(localized: "section.weekendAdjustments"))
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                weekendRow(String(localized: "field.saturday"), selection: $saturdayAdj)
                weekendRow(String(localized: "field.sunday"), selection: $sundayAdj)
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: PPRadius.lg)
                    .stroke(Color.ppBorder, lineWidth: 1)
            )

            // Naming
            VStack(alignment: .leading, spacing: PPSpacing.lg) {
                Text(String(localized: "section.naming"))
                    .font(.ppTitle3)
                    .foregroundColor(.ppTextPrimary)

                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    HStack(spacing: 2) {
                        Text(String(localized: "field.namePattern")).font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                        Text("*").font(.ppCallout).foregroundColor(.ppDestructive)
                    }
                    TextField("{month} {year}", text: $namePattern)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                        .padding(.horizontal, PPSpacing.lg).padding(.vertical, PPSpacing.md)
                        .background(Color.ppSurface).clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                }

                Text(String(localized: "autoCreation.availableVars"))
                    .font(.ppCaption).foregroundColor(.ppTextTertiary)
                Text("{MONTH} {MONTH_SHORT} {YEAR} {YEAR_SHORT} {START_DATE} {END_DATE} {PERIOD_NUMBER}")
                    .font(.system(size: 11, design: .monospaced)).foregroundColor(.ppTextTertiary)

                // Preview
                VStack(alignment: .leading, spacing: PPSpacing.xs) {
                    Text(String(localized: "autoCreation.preview").uppercased())
                        .font(.ppOverline).foregroundColor(.ppTextSecondary).tracking(1)
                    Text(namePatternPreview)
                        .font(.ppHeadline).foregroundColor(.ppTextPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PPSpacing.md)
                .background(Color.ppSurface)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))

                // Summary line
                Text(summaryLine)
                    .font(.ppCaption).foregroundColor(.ppTextTertiary)
            }
            .padding(PPSpacing.lg)
            .background(Color.ppCard)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))

            // Actions
            VStack(spacing: PPSpacing.md) {
                Button {
                    Task { await saveSchedule() }
                } label: {
                    Group {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text(schedule == nil ? String(localized: "button.enableAutoCreation") : String(localized: "button.saveChanges"))
                                .font(.ppHeadline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PPSpacing.md)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.primary)
                .buttonBorderShape(.capsule)
                .disabled(isSaving || namePattern.trimmingCharacters(in: .whitespaces).isEmpty)

                if schedule != nil {
                    Button(role: .destructive) {
                        Task { await deleteSchedule() }
                    } label: {
                        Text(String(localized: "button.disableAutoCreation"))
                            .font(.ppCallout)
                            .foregroundColor(.ppDestructive)
                    }
                }
            }
        }
    }

    // MARK: - Recurrence Option

    private func recurrenceOption(_ value: String, title: String, desc: String) -> some View {
        let isSelected = recurrenceMethod == value
        return Button {
            recurrenceMethod = value
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: PPSpacing.md) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? theme.primary : .ppTextTertiary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.ppCallout).fontWeight(.semibold)
                        .foregroundColor(isSelected ? .ppTextPrimary : .ppTextSecondary)
                    Text(desc).font(.ppCaption).foregroundColor(.ppTextTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PPSpacing.md)
            .background(isSelected ? theme.primary.opacity(0.08) : Color.ppSurface)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.md)
                .stroke(isSelected ? theme.primary : Color.ppBorder, lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview Helpers

    private var namePatternPreview: String {
        let now = Date()
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = .current

        var result = namePattern
        formatter.dateFormat = "MMMM"
        result = result.replacingOccurrences(of: "{MONTH}", with: formatter.string(from: now))
        formatter.dateFormat = "MMM"
        result = result.replacingOccurrences(of: "{MONTH_SHORT}", with: formatter.string(from: now))
        formatter.dateFormat = "yyyy"
        result = result.replacingOccurrences(of: "{YEAR}", with: formatter.string(from: now))
        formatter.dateFormat = "yy"
        result = result.replacingOccurrences(of: "{YEAR_SHORT}", with: formatter.string(from: now))
        formatter.dateFormat = "dd/MM"
        result = result.replacingOccurrences(of: "{START_DATE}", with: formatter.string(from: now))
        if let endDate = cal.date(byAdding: .day, value: 30, to: now) {
            result = result.replacingOccurrences(of: "{END_DATE}", with: formatter.string(from: endDate))
        }
        result = result.replacingOccurrences(of: "{PERIOD_NUMBER}", with: "1")
        return result.isEmpty ? "—" : result
    }

    private var summaryLine: String {
        let unitLabel: String
        switch durationUnit {
        case "days": unitLabel = durationValue == 1 ? String(localized: "unit.day") : String(localized: "unit.days")
        case "weeks": unitLabel = durationValue == 1 ? String(localized: "unit.week") : String(localized: "unit.weeks")
        default: unitLabel = durationValue == 1 ? String(localized: "unit.month") : String(localized: "unit.months")
        }
        return "\(generateAhead) \(String(localized: "autoCreation.periodsPrepared")) · \(String(localized: "autoCreation.every")) \(durationValue) \(unitLabel), \(String(localized: "autoCreation.startingOn")) \(startDay)"
    }

    // MARK: - Weekend Row

    private func weekendRow(_ day: String, selection: Binding<String>) -> some View {
        HStack {
            Text(String(localized: "autoCreation.ifDay \(day)"))
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary)
            Spacer()
            Picker("", selection: selection) {
                Text(String(localized: "autoCreation.keep")).tag("keep")
                Text(String(localized: "autoCreation.moveToFriday")).tag("friday")
                Text(String(localized: "autoCreation.moveToMonday")).tag("monday")
            }
            .tint(theme.primary)
        }
    }

    // MARK: - API

    private func loadSchedule() async {
        isLoading = true
        do {
            let s: PeriodSchedule = try await appState.apiClient.request(.schedule)
            schedule = s
            recurrenceMethod = s.recurrenceMethod ?? "dayOfMonth"
            startDay = s.startDayOfTheMonth ?? 1
            durationValue = s.periodDuration ?? 1
            durationUnit = s.durationUnit ?? "months"
            saturdayAdj = s.saturdayPolicy ?? "keep"
            sundayAdj = s.sundayPolicy ?? "keep"
            namePattern = s.namePattern ?? "{month} {year}"
            generateAhead = s.generateAhead ?? 3
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
            let scheduleType: String
            let recurrenceMethod: String
            let startDayOfTheMonth: Int
            let periodDuration: Int
            let durationUnit: String
            let saturdayPolicy: String
            let sundayPolicy: String
            let namePattern: String
            let generateAhead: Int
        }

        let request = ScheduleRequest(
            scheduleType: "automatic",
            recurrenceMethod: recurrenceMethod,
            startDayOfTheMonth: startDay,
            periodDuration: durationValue,
            durationUnit: durationUnit,
            saturdayPolicy: saturdayAdj,
            sundayPolicy: sundayAdj,
            namePattern: namePattern.trimmingCharacters(in: .whitespaces),
            generateAhead: generateAhead
        )

        do {
            let endpoint: APIEndpoint = schedule == nil ? .createSchedule : .updateSchedule
            let s: PeriodSchedule = try await appState.apiClient.request(endpoint, body: request)
            schedule = s
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
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
