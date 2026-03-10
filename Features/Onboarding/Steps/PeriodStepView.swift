import SwiftUI

struct PeriodStepView: View {
    @ObservedObject var vm: OnboardingViewModel
@Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PPSpacing.xl) {

                // Description
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Text("Periods are how PiggyPulse slices your timeline for tracking. The default — monthly, starting on the 1st — works for most people.")
                        .font(.ppBody).foregroundColor(.ppTextPrimary)
                    Text("You can further customize periods later in the Periods screen, including renaming them or adjusting individual start dates.")
                        .font(.ppCallout).foregroundColor(.ppTextSecondary)
                }

                // Customize toggle
                VStack(alignment: .leading, spacing: PPSpacing.md) {
                    Text("Configuration")
                        .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                    Picker("", selection: $vm.customize) {
                        Text("Use default").tag(false)
                        Text("Customize").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                // Custom fields
                if vm.customize {
                    VStack(spacing: PPSpacing.md) {
                        NumberStepperView(
                            label: "Start Day",
                            description: "The day of the month your period begins. Capped at 28 so it exists every month.",
                            value: $vm.startDay
                        )
                        NumberStepperView(
                            label: "Period Length",
                            description: "How many months each period spans. Most people use 1.",
                            value: $vm.periodLength
                        )
                        NumberStepperView(
                            label: "Periods to Prepare",
                            description: "How many future periods to create in advance.",
                            value: $vm.periodsToPrepare
                        )

                        // Weekend adjustments
                        VStack(alignment: .leading, spacing: PPSpacing.md) {
                            Text("Weekend Days")
                                .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                            Text("If the period start date falls on a weekend, PiggyPulse can shift it to the nearest weekday. This only affects when a period is recorded as starting — it does not change how long the period lasts.")
                                .font(.ppCaption).foregroundColor(.ppTextSecondary)

                            HStack {
                                Text("If it lands on Saturday")
                                    .font(.ppCallout).foregroundColor(.ppTextPrimary)
                                Spacer()
                                Picker("Saturday", selection: $vm.saturdayBehavior) {
                                    ForEach(WeekendBehavior.allCases, id: \.self) { opt in
                                        Text(opt.label).tag(opt)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.ppPrimary)
                            }

                            HStack {
                                Text("If it lands on Sunday")
                                    .font(.ppCallout).foregroundColor(.ppTextPrimary)
                                Spacer()
                                Picker("Sunday", selection: $vm.sundayBehavior) {
                                    ForEach(WeekendBehavior.allCases, id: \.self) { opt in
                                        Text(opt.label).tag(opt)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.ppPrimary)
                            }
                        }
                        .padding(PPSpacing.lg)
                        .background(Color.ppCard)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                    }
                    .animation(.easeInOut(duration: 0.2), value: vm.customize)
                }
            }
            .padding(PPSpacing.xl)
        }
    }
}
