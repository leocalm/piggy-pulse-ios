import SwiftUI

struct NumberStepperView: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    let description: String
    @Binding var value: Int
    var min: Int = 1
    var max: Int = 28

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.xs) {
            Text(label)
                .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
            Text(description)
                .font(.ppCaption).foregroundColor(.ppTextSecondary(colorScheme))
            HStack {
                Button {
                    if value > min { value -= 1 }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 36, height: 36)
                        .background(Color.ppSurface(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                }
                .disabled(value <= min)
                .foregroundColor(value <= min ? .ppTextTertiary(colorScheme) : .ppTextPrimary(colorScheme))

                Spacer()
                Text("\(value)")
                    .font(.ppTitle3).fontWeight(.semibold).foregroundColor(.ppTextPrimary(colorScheme))
                    .frame(minWidth: 40, alignment: .center)
                Spacer()

                Button {
                    if value < max { value += 1 }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 36, height: 36)
                        .background(Color.ppSurface(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                }
                .disabled(value >= max)
                .foregroundColor(value >= max ? .ppTextTertiary(colorScheme) : .ppTextPrimary(colorScheme))
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder(colorScheme), lineWidth: 1))
    }
}
