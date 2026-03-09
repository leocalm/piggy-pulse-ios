import SwiftUI

struct EntityPickerView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let cardType: DashboardCardType

    @State private var availableEntities: [AvailableEntity] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if availableEntities.isEmpty {
                Text("No available entities")
                    .font(.ppBody)
                    .foregroundColor(.ppTextSecondary(colorScheme))
            } else {
                List(availableEntities) { entity in
                    Button {
                        Task { await addEntity(entity) }
                    } label: {
                        HStack {
                            Text(entity.name)
                                .font(.ppBody)
                                .foregroundColor(.ppTextPrimary(colorScheme))
                            Spacer()
                            if entity.alreadyAdded {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.ppPrimary)
                            }
                        }
                    }
                    .disabled(entity.alreadyAdded)
                }
            }
        }
        .navigationTitle("Select \(cardType.displayName)")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadEntities() }
    }

    private func loadEntities() async {
        do {
            let available = try await viewModel.repository.fetchAvailableCards()
            availableEntities = available.entityCards
                .first { $0.cardType == cardType.rawValue }?
                .availableEntities ?? []
        } catch {}
        isLoading = false
    }

    private func addEntity(_ entity: AvailableEntity) async {
        let maxPosition = viewModel.layout.map(\.position).max() ?? -1
        do {
            try await viewModel.addCard(CreateDashboardCardRequest(
                cardType: cardType.rawValue,
                entityId: entity.id,
                position: maxPosition + 1,
                enabled: true
            ))
            dismiss()
        } catch {}
    }
}
