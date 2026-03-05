import SwiftUI

struct PPTextField: View {
    let label: String
    let placeholder: String
    let isRequired: Bool
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil

    @State private var showPassword = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            // Label
            HStack(spacing: 2) {
                Text(label)
                    .font(.ppCallout)
                    .fontWeight(.semibold)
                    .foregroundColor(.ppTextPrimary)
                if isRequired {
                    Text("*")
                        .font(.ppCallout)
                        .foregroundColor(.ppDestructive)
                }
            }

            // Input field
            HStack {
                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                            .textContentType(textContentType)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .textContentType(textContentType)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                }
                .font(.ppBody)
                .foregroundColor(.ppTextPrimary)
                .focused($isFocused)

                if isSecure {
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.ppTextSecondary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, PPSpacing.lg)
            .padding(.vertical, PPSpacing.md)
            .background(Color.ppSurface)
            .cornerRadius(PPRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: PPRadius.md)
                    .stroke(isFocused ? Color.ppPrimary : Color.ppBorder, lineWidth: 1)
            )
        }
    }
}
