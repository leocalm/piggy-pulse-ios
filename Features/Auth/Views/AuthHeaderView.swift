import SwiftUI

struct AuthHeaderView: View {
    @Environment(\.themeManager) private var theme

    let tagline: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: theme.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: PPSpacing.md) {
                Image("piggy-logo-white")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 64)

                Text("PiggyPulse")
                    .font(.ppTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(tagline)
                    .font(.ppCallout)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PPSpacing.xxl)
            }
            .padding(.vertical, PPSpacing.xxxl)
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .top)
    }
}

/// Side panel version of the auth header for iPad split layout.
struct AuthBrandingPanel: View {
    @Environment(\.themeManager) private var theme

    let tagline: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: theme.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: PPSpacing.lg) {
                Spacer()

                Image("piggy-logo-white")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)

                Text("PiggyPulse")
                    .font(.ppLargeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(tagline)
                    .font(.ppBody)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PPSpacing.xxxl)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: [.top, .leading, .bottom])
    }
}
