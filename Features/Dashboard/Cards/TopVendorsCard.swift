import SwiftUI

struct TopVendorsCard: View {
    let vendors: [TopVendorItem]
    let currencyCode: String
    @Environment(\.themeManager) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.lg) {
            Text(String(localized: "widget.topVendors.name").uppercased())
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)

            if vendors.isEmpty {
                Text(String(localized: "widget.topVendors.empty"))
                    .font(.ppCallout)
                    .foregroundColor(.ppTextTertiary)
            } else {
                let maxSpend = vendors.first?.totalSpent ?? 1
                ForEach(vendors, id: \.vendorId) { vendor in
                    VStack(alignment: .leading, spacing: PPSpacing.xs) {
                        HStack {
                            Text(vendor.vendorName)
                                .font(.ppCallout)
                                .foregroundColor(.ppTextPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text(formatCurrency(vendor.totalSpent, code: currencyCode))
                                .font(.ppCallout)
                                .fontDesign(.monospaced)
                                .foregroundColor(.ppTextPrimary)
                        }

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.primary.opacity(0.6))
                                .frame(width: geo.size.width * (maxSpend > 0 ? Double(vendor.totalSpent) / Double(maxSpend) : 0))
                        }
                        .frame(height: 4)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(String(localized: "accessibility.topVendors.bar \(vendor.vendorName) \(formatCurrency(vendor.totalSpent, code: currencyCode))"))
                    }
                }
            }
        }
        .dashboardCard()
    }
}
