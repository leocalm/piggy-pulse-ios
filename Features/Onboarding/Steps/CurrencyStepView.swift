import SwiftUI

struct CurrencyStepView: View {
    @ObservedObject var vm: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeManager) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header text
            VStack(alignment: .leading, spacing: PPSpacing.sm) {
                Text(String(localized: "currency.title"))
                    .font(.ppTitle3).fontWeight(.bold).foregroundColor(.ppTextPrimary)

                Text(String(localized: "currency.requiredStep"))
                    .font(.ppCallout).fontWeight(.semibold).foregroundColor(theme.primary)

                Text(String(localized: "currency.description"))
                    .font(.ppBody).foregroundColor(.ppTextSecondary)
            }
            .padding(.horizontal, PPSpacing.xl)
            .padding(.top, PPSpacing.lg)
            .padding(.bottom, PPSpacing.md)

            // Search field
            HStack(spacing: PPSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.ppTextTertiary)
                TextField(String(localized: "currency.searchPlaceholder"), text: $vm.currencySearch)
                    .font(.ppBody)
                    .foregroundColor(.ppTextPrimary)
                if !vm.currencySearch.isEmpty {
                    Button {
                        vm.currencySearch = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.ppTextTertiary)
                    }
                }
            }
            .padding(.horizontal, PPSpacing.md)
            .padding(.vertical, PPSpacing.sm)
            .background(Color.ppSurface)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
            .padding(.horizontal, PPSpacing.xl)
            .padding(.bottom, PPSpacing.sm)

            // Currency list
            if vm.currencies.isEmpty {
                Spacer()
                ProgressView().frame(maxWidth: .infinity)
                Spacer()
            } else {
                List {
                    ForEach(vm.filteredCurrencies) { currency in
                        currencyRow(currency)
                            .listRowBackground(
                                vm.selectedCurrencyId == currency.id
                                    ? theme.primary.opacity(0.08)
                                    : Color.ppCard
                            )
                            .listRowSeparatorTint(Color.ppBorder)
                    }
                }
                .listStyle(.plain)
                .background(Color.ppBackground)
                .scrollContentBackground(.hidden)
            }

            // Multi-currency note
            HStack(alignment: .top, spacing: PPSpacing.sm) {
                Image(systemName: "info.circle").foregroundColor(.ppTextTertiary).font(.ppCaption)
                Text(String(localized: "currency.multiCurrencyNote"))
                    .font(.ppCaption).foregroundColor(.ppTextTertiary)
            }
            .padding(PPSpacing.md)
            .background(Color.ppSurface)
            .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
            .padding(.horizontal, PPSpacing.xl)
            .padding(.bottom, PPSpacing.sm)
        }
        .task { await vm.loadCurrencies() }
    }

    private func currencyRow(_ currency: Currency) -> some View {
        Button {
            vm.selectedCurrencyId = currency.id
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: PPSpacing.md) {
                Text(currency.symbol)
                    .font(.ppTitle3)
                    .frame(width: 36, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.name)
                        .font(.ppCallout)
                        .foregroundColor(.ppTextPrimary)
                    Text(currency.code)
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                }

                Spacer()

                if vm.selectedCurrencyId == currency.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.primary)
                        .font(.ppBody)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
