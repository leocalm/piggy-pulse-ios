import SwiftUI

// MARK: - Password Strength Score

struct PasswordStrength {
    static func score(for password: String) -> Int {
        guard !password.isEmpty else { return 0 }
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }
        return score
    }

    static func label(for score: Int) -> LocalizedStringKey {
        switch score {
        case 0, 1: return "auth.password.veryWeak"
        case 2:    return "auth.password.weak"
        case 3:    return "auth.password.fair"
        case 4:    return "auth.password.strong"
        default:   return "auth.password.veryStrong"
        }
    }

    static func color(for score: Int) -> Color {
        // Using neutral/warm palette — no red/green judgment per design guidelines
        switch score {
        case 0, 1: return Color(rgb: 0xC4786A) // ppDestructive (same as error states)
        case 2:    return Color(rgb: 0xF0A25C) // amber
        case 3:    return Color(rgb: 0x7CA8C4) // blue-ish (fair)
        case 4:    return Color(rgb: 0x8B7EC8) // primary purple
        default:   return Color(rgb: 0x6B8F71) // sage (strong)
        }
    }
}

// MARK: - View

struct PasswordStrengthBar: View {
    let password: String

    private var score: Int { PasswordStrength.score(for: password) }
    private var barColor: Color { PasswordStrength.color(for: score) }
    private var label: LocalizedStringKey { PasswordStrength.label(for: score) }

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.xs) {
            HStack(spacing: PPSpacing.xs) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: PPRadius.sm)
                        .fill(index < filledSegments ? barColor : Color.ppBorder)
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.2), value: score)
                }
            }

            Text(label)
                .font(.ppCaption)
                .foregroundColor(barColor)
                .animation(.easeInOut(duration: 0.2), value: score)
        }
    }

    private var filledSegments: Int {
        switch score {
        case 0:    return 0
        case 1:    return 1
        case 2:    return 2
        case 3:    return 3
        case 4:    return 3
        default:   return 4
        }
    }
}
