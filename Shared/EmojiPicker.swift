import SwiftUI
import UIKit

// MARK: - Emoji Picker

/// A hybrid emoji picker: shows a quick-pick grid of common emojis,
/// plus a "More..." button that opens the native emoji keyboard.
struct EmojiPicker: View {
    @Binding var selection: String
    @Environment(\.themeManager) private var theme

    @State private var showEmojiKeyboard = false

    private let quickPicks = [
        "🛒", "🏠", "🚗", "💡", "🎮", "👕", "🍽️", "☕",
        "✈️", "🏥", "📚", "🎵", "💼", "🎁", "🐾", "💰",
        "📱", "🏋️", "🎬", "🧾", "💳", "🚌", "🍕", "🛍️",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.sm) {
            Text(String(localized: "field.icon"))
                .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: PPSpacing.sm) {
                ForEach(quickPicks, id: \.self) { emoji in
                    emojiCell(emoji)
                }

                // "More" button
                Button {
                    showEmojiKeyboard = true
                } label: {
                    Text("…")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.ppTextSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.ppSurface)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: PPRadius.sm)
                                .stroke(Color.ppBorder, lineWidth: 1)
                        )
                }
            }

            // Show selected emoji if it's not in the quick picks
            if !selection.isEmpty && !quickPicks.contains(selection) {
                HStack(spacing: PPSpacing.sm) {
                    Text(String(localized: "emoji.selected"))
                        .font(.ppCaption).foregroundColor(.ppTextSecondary)
                    emojiCell(selection)
                }
            }
        }
        .sheet(isPresented: $showEmojiKeyboard) {
            EmojiKeyboardSheet(selection: $selection)
        }
    }

    private func emojiCell(_ emoji: String) -> some View {
        Text(emoji)
            .font(.system(size: 24))
            .frame(width: 36, height: 36)
            .background(selection == emoji ? theme.primary.opacity(0.3) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: PPRadius.sm)
                    .stroke(selection == emoji ? theme.primary : Color.clear, lineWidth: 1)
            )
            .onTapGesture { selection = emoji }
    }
}

// MARK: - Emoji Keyboard Sheet

/// A minimal sheet that presents a text field forcing the emoji keyboard.
/// Accepts only emoji input, auto-dismisses after selection.
private struct EmojiKeyboardSheet: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var theme
    @State private var inputText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: PPSpacing.xl) {
                Text(String(localized: "emoji.pickTitle"))
                    .font(.ppTitle3).foregroundColor(.ppTextPrimary)

                Text(String(localized: "emoji.pickSubtitle"))
                    .font(.ppCallout).foregroundColor(.ppTextSecondary)

                // Large preview of selected emoji
                Text(inputText.isEmpty ? "?" : inputText)
                    .font(.system(size: 64))
                    .frame(width: 100, height: 100)
                    .background(Color.ppSurface)
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: PPRadius.lg)
                            .stroke(Color.ppBorder, lineWidth: 1)
                    )

                // Hidden emoji-only text field
                EmojiTextField(text: $inputText)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)

                Button {
                    if !inputText.isEmpty {
                        selection = inputText
                    }
                    dismiss()
                } label: {
                    Text(String(localized: "common.done"))
                        .font(.ppHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PPSpacing.md)
                        .background(inputText.isEmpty ? theme.primary.opacity(0.4) : theme.primary)
                        .clipShape(Capsule())
                }
                .disabled(inputText.isEmpty)

                Spacer()
            }
            .padding(PPSpacing.xl)
            .background(Color.ppBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundColor(.ppTextSecondary)
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            // Auto-focus the emoji field after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                EmojiTextField.becomeFirstResponderGlobal = true
            }
        }
        .onChange(of: inputText) { _, newValue in
            // Filter to only emoji characters, keep first one
            let filtered = newValue.filter { $0.isEmoji }
            if let first = filtered.first {
                inputText = String(first)
            } else {
                inputText = ""
            }
        }
    }
}

// MARK: - UIKit Emoji-Only TextField

/// A UITextField wrapper that forces the emoji keyboard.
struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String
    static var becomeFirstResponderGlobal = false

    func makeUIView(context: Context) -> UITextField {
        let field = EmojiUITextField()
        field.delegate = context.coordinator
        field.textAlignment = .center
        field.font = .systemFont(ofSize: 48)
        field.returnKeyType = .done
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if Self.becomeFirstResponderGlobal {
            Self.becomeFirstResponderGlobal = false
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Allow deletions
            if string.isEmpty { return true }
            // Only allow emoji
            let filtered = string.filter { $0.isEmoji }
            if let first = filtered.first {
                text = String(first)
                return false
            }
            return false
        }
    }
}

/// A UITextField subclass that forces the emoji keyboard.
private class EmojiUITextField: UITextField {
    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return super.textInputMode
    }
}

// MARK: - Character Emoji Detection

extension Character {
    /// Returns true if this character is an emoji.
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}
