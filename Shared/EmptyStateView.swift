import SwiftUI

/// Reusable empty state component for list screens.
/// Displays an icon, title, description, numbered onboarding steps, tips, and an action button.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var steps: [EmptyStateStep] = []
    var tips: [String] = []
    var actionLabel: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: PPSpacing.xl) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
                .padding(.bottom, PPSpacing.sm)

            // Title & message
            Text(title)
                .font(.ppTitle3)
                .foregroundColor(.ppTextPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.ppCallout)
                .foregroundColor(.ppTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            // Numbered steps
            if !steps.isEmpty {
                VStack(alignment: .leading, spacing: PPSpacing.md) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: PPSpacing.md) {
                            Text("\(index + 1)")
                                .font(.ppCaption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.ppTextSecondary.opacity(0.5))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: PPSpacing.xs) {
                                Text(step.title)
                                    .font(.ppHeadline)
                                    .foregroundColor(.ppTextPrimary)
                                Text(step.description)
                                    .font(.ppCaption)
                                    .foregroundColor(.ppTextSecondary)
                            }
                        }
                    }
                }
                .padding(PPSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.ppElevated)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
            }

            // Action button
            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.ppHeadline)
                }
                .buttonStyle(.borderedProminent)
            }

            // Tips
            if !tips.isEmpty {
                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                    Label(String(localized: "emptyState.tips"), systemImage: "lightbulb.fill")
                        .font(.ppCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(.ppTextSecondary)

                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: PPSpacing.sm) {
                            Text("·")
                                .foregroundColor(.ppTextTertiary)
                            Text(tip)
                                .font(.ppCaption)
                                .foregroundColor(.ppTextSecondary)
                        }
                    }
                }
                .padding(PPSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.ppElevated)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
            }
        }
        .padding(PPSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PPRadius.lg)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
    }
}

// MARK: - Step Model

struct EmptyStateStep {
    let title: String
    let description: String
}
