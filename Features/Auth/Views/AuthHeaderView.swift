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
