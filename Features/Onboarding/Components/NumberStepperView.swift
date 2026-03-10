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
                .font(.ppCallout).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
            Text(description)
                .font(.ppCaption).foregroundColor(.ppTextSecondary)
            HStack {
                Button {
                    if value > min { value -= 1 }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 36, height: 36)
                        .background(Color.ppSurface)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                }
                .disabled(value <= min)
                .foregroundColor(value <= min ? .ppTextTertiary : .ppTextPrimary)

                Spacer()
                Text("\(value)")
                    .font(.ppTitle3).fontWeight(.semibold).foregroundColor(.ppTextPrimary)
                    .frame(minWidth: 40, alignment: .center)
                Spacer()

                Button {
                    if value < max { value += 1 }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 36, height: 36)
                        .background(Color.ppSurface)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                }
                .disabled(value >= max)
                .foregroundColor(value >= max ? .ppTextTertiary : .ppTextPrimary)
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
    }
}
