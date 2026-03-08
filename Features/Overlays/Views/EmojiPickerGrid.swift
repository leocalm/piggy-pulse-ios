import SwiftUI

struct EmojiPickerGrid: View {
    @Binding var selectedEmoji: String?

    private let emojis: [String] = [
        // Travel & Places
        "✈️", "🌍", "🏖️", "🏔️", "🗺️", "🧳", "🚢", "🏕️",
        // Food & Drink
        "🍕", "🍣", "🍷", "☕️", "🍔", "🥗", "🍜", "🧁",
        // Activities & Events
        "🎉", "🎭", "🎵", "⚽️", "🏋️", "🎮", "🎨", "📚",
        // Money & Goals
        "💰", "🎯", "💳", "🏆", "💼", "📊", "🛒", "🏠",
        // Nature & Seasons
        "🌸", "❄️", "🌞", "🍂", "🌈", "🦋", "🌴", "🎄",
        // Misc
        "❤️", "⭐️", "🔥", "💡", "🎁", "🚀", "🦄", "🍀"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: PPSpacing.sm), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: PPSpacing.sm) {
            ForEach(emojis, id: \.self) { emoji in
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 40, height: 40)
                    .background(
                        selectedEmoji == emoji
                            ? Color.ppPrimary.opacity(0.2)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: PPRadius.sm)
                            .stroke(
                                selectedEmoji == emoji ? Color.ppPrimary : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if selectedEmoji == emoji {
                            selectedEmoji = nil
                        } else {
                            selectedEmoji = emoji
                        }
                    }
            }
        }
    }
}
