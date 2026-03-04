import SwiftUI

struct LoginView: View {
    var body: some View {
        VStack {
            Text("PiggyPulse")
                .font(.ppLargeTitle)
                .foregroundColor(.ppPrimary)
            Text("Login placeholder")
                .foregroundColor(.ppTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ppBackground)
    }
}
