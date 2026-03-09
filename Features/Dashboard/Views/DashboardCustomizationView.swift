import SwiftUI

struct DashboardCustomizationView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.colorScheme) private var colorScheme

    var standardCards: [DashboardCardConfig] {
        viewModel.layout
            .filter { !$0.cardType.isEntityCard }
            .sorted { $0.position < $1.position }
    }

    var entityCards: [DashboardCardConfig] {
        viewModel.layout
            .filter { $0.cardType.isEntityCard }
            .sorted { $0.position < $1.position }
    }

    var body: some View {
        List {
            Section("Standard Cards") {
                ForEach(standardCards) { card in
                    standardCardRow(card: card)
                }
                .onMove { from, to in
                    Task { await reorderStandardCards(from: from, to: to) }
                }
            }

            Section("My Entity Cards") {
                ForEach(entityCards) { card in
                    entityCardRow(card: card)
                }
                .onMove { from, to in
                    Task { await reorderEntityCards(from: from, to: to) }
                }
                .onDelete { indexSet in
                    Task { await deleteEntityCards(at: indexSet) }
                }
            }

            Section {
                NavigationLink {
                    EntityPickerView(viewModel: viewModel, cardType: .accountSummary)
                } label: {
                    Label("Add Account Card...", systemImage: "building.columns.fill")
                }
                NavigationLink {
                    EntityPickerView(viewModel: viewModel, cardType: .categoryBreakdown)
                } label: {
                    Label("Add Category Card...", systemImage: "folder.fill")
                }

            }

            Section {
                Button(role: .destructive) {
                    Task { try? await viewModel.resetLayout() }
                } label: {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("Dashboard Cards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }

    // MARK: - Standard card row

    private func standardCardRow(card: DashboardCardConfig) -> some View {
        HStack {
            Image(systemName: card.cardType.iconName)
                .foregroundColor(.ppPrimary)
                .frame(width: 24)
            Text(card.cardType.displayName)
                .font(.ppHeadline)
                .foregroundColor(.ppTextPrimary(colorScheme))
            Spacer()
            Toggle("", isOn: Binding(
                get: { card.enabled },
                set: { newValue in
                    Task { try? await viewModel.toggleCard(card.id, enabled: newValue) }
                }
            ))
            .labelsHidden()
        }
    }

    // MARK: - Entity card row

    private func entityCardRow(card: DashboardCardConfig) -> some View {
        HStack {
            Image(systemName: card.cardType.iconName)
                .foregroundColor(.ppPrimary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(card.cardType.displayName)
                    .font(.ppHeadline)
                    .foregroundColor(.ppTextPrimary(colorScheme))
                if card.entityId != nil {
                    Text("Entity card")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary(colorScheme))
                }
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { card.enabled },
                set: { newValue in
                    Task { try? await viewModel.toggleCard(card.id, enabled: newValue) }
                }
            ))
            .labelsHidden()
        }
    }

    // MARK: - Auto-save actions

    private func reorderStandardCards(from: IndexSet, to: Int) async {
        var cards = standardCards
        cards.move(fromOffsets: from, toOffset: to)
        let allCards = cards + entityCards
        let reorder = ReorderRequest(order: allCards.enumerated().map { i, card in
            ReorderItem(id: card.id, position: i)
        })
        try? await viewModel.reorderCards(reorder)
    }

    private func reorderEntityCards(from: IndexSet, to: Int) async {
        var cards = entityCards
        cards.move(fromOffsets: from, toOffset: to)
        let allCards = standardCards + cards
        let reorder = ReorderRequest(order: allCards.enumerated().map { i, card in
            ReorderItem(id: card.id, position: i)
        })
        try? await viewModel.reorderCards(reorder)
    }

    private func deleteEntityCards(at indexSet: IndexSet) async {
        let cards = entityCards
        for index in indexSet {
            try? await viewModel.deleteCard(cards[index].id)
        }
    }
}
