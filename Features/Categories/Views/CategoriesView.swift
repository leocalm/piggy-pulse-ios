import SwiftUI
import TipKit

struct CategoriesView: View {
    @EnvironmentObject var appState: AppState
@Environment(\.colorScheme) private var colorScheme
    @State private var incoming: [CategoryManagementItem] = []
    @State private var outgoing: [CategoryManagementItem] = []
    @State private var archived: [CategoryManagementItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showArchived = false
    @State private var showAddSheet = false
    @State private var editingCategory: CategoryManagementItem?
    @State private var categoryToDelete: CategoryManagementItem?
    @State private var categoryToArchive: CategoryManagementItem?
    @State private var searchText = ""

    private let categoriesTip = CategoriesTip()

    private var filteredIncoming: [CategoryManagementItem] {
        if searchText.isEmpty { return incoming }
        return incoming.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredOutgoing: [CategoryManagementItem] {
        if searchText.isEmpty { return outgoing }
        return outgoing.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredArchived: [CategoryManagementItem] {
        if searchText.isEmpty { return archived }
        return archived.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var allCategoriesEmpty: Bool {
        incoming.isEmpty && outgoing.isEmpty && archived.isEmpty
    }

    var body: some View {
        List {
                // Tip
                Section {
                    TipView(categoriesTip)
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                }

                // Stats bar
                if !isLoading && errorMessage == nil && !allCategoriesEmpty {
                    Section {
                        categoryStatsBar
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    }

                    // Search field
                    Section {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.ppTextTertiary)
                            TextField(String(localized: "categories.search"), text: $searchText)
                                .font(.ppBody)
                                .foregroundColor(.ppTextPrimary)
                            if !searchText.isEmpty {
                                Button { searchText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.ppTextTertiary)
                                }
                            }
                        }
                        .padding(PPSpacing.md)
                        .background(Color.ppCard)
                        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    }
                }

                if let error = errorMessage {
                    Section {
                        VStack(spacing: PPSpacing.md) {
                            Image(systemName: "exclamationmark.triangle").font(.system(size: 32)).foregroundColor(.ppAmber)
                            Text(error).font(.ppBody).foregroundColor(.ppTextSecondary)
                            Button("Retry") { Task { await load() } }.font(.ppHeadline).foregroundColor(.ppPrimary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, PPSpacing.xxxl)
                        .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                    }
                } else if allCategoriesEmpty {
                    Section {
                        EmptyStateView(
                            icon: "tag",
                            title: String(localized: "categories.empty.title"),
                            message: String(localized: "categories.empty.message"),
                            steps: [
                                EmptyStateStep(
                                    title: String(localized: "categories.empty.step1.title"),
                                    description: String(localized: "categories.empty.step1.description")
                                ),
                                EmptyStateStep(
                                    title: String(localized: "categories.empty.step2.title"),
                                    description: String(localized: "categories.empty.step2.description")
                                ),
                                EmptyStateStep(
                                    title: String(localized: "categories.empty.step3.title"),
                                    description: String(localized: "categories.empty.step3.description")
                                ),
                            ],
                            tips: [
                                String(localized: "categories.empty.tip1"),
                                String(localized: "categories.empty.tip2"),
                                String(localized: "categories.empty.tip3"),
                            ],
                            actionLabel: String(localized: "categories.empty.action"),
                            action: { showAddSheet = true }
                        )
                        .listRowBackground(Color.ppBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    }
                } else {
                    categorySection(String(localized: "INCOMING"), categories: filteredIncoming, color: .ppCyan)
                    categorySection(String(localized: "OUTGOING"), categories: filteredOutgoing, color: .ppPrimary)

                    if !filteredArchived.isEmpty {
                        Section {
                            if showArchived {
                                ForEach(filteredArchived) { cat in
                                    categoryRow(cat, dimmed: true)
                                        .listRowBackground(Color.ppBackground)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                                }
                            }
                        } header: {
                            Button {
                                withAnimation { showArchived.toggle() }
                            } label: {
                                HStack {
                                    Text("ARCHIVED").font(.ppOverline).foregroundColor(.ppTextSecondary).tracking(1)
                                    Spacer()
                                    Text("\(archived.count)").font(.ppCaption).foregroundColor(.ppTextSecondary)
                                        .padding(.horizontal, PPSpacing.sm).padding(.vertical, 2)
                                        .background(Color.ppCard).clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
                                    Image(systemName: showArchived ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12)).foregroundColor(.ppTextSecondary)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.ppBackground)
            .refreshable { await load() }
            .task { await load() }
            .sheet(isPresented: $showAddSheet, onDismiss: { Task { await load() } }) {
                AddCategorySheet { }.environmentObject(appState)
            }
            .sheet(item: $editingCategory) { cat in
                EditCategorySheet(category: cat) { Task { await load() } }
                    .environmentObject(appState)
            }
            .confirmationDialog("Archive \"\(categoryToArchive?.name ?? "")\"?", isPresented: Binding(get: { categoryToArchive != nil }, set: { if !$0 { categoryToArchive = nil } }), titleVisibility: .visible) {
                Button("Archive", role: .destructive) {
                    if let cat = categoryToArchive { Task { await archiveCategory(cat) } }
                }
                Button("Cancel", role: .cancel) { categoryToArchive = nil }
            } message: {
                Text("This category will be hidden but its history will be preserved.")
            }
            .confirmationDialog("Delete \"\(categoryToDelete?.name ?? "")\"?", isPresented: Binding(get: { categoryToDelete != nil }, set: { if !$0 { categoryToDelete = nil } }), titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let cat = categoryToDelete { Task { await deleteCategory(cat) } }
                }
                Button("Cancel", role: .cancel) { categoryToDelete = nil }
            } message: {
                Text("This category will be permanently deleted.")
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
    }

    private var categoryStatsBar: some View {
        let allActive = incoming + outgoing
        let totalCount = allActive.count
        let incomeCount = incoming.count
        let expenseCount = outgoing.count
        let archivedCount = archived.count

        return HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("\(totalCount)")
                    .font(.ppCallout)
                    .fontWeight(.semibold)
                    .foregroundColor(.ppTextPrimary)
                Text(String(localized: "categories.stats.total"))
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: 4) {
                Text("\(incomeCount)")
                    .font(.ppCallout)
                    .fontWeight(.semibold)
                    .foregroundColor(.ppTextPrimary)
                Text(String(localized: "categories.stats.income"))
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: 4) {
                Text("\(expenseCount)")
                    .font(.ppCallout)
                    .fontWeight(.semibold)
                    .foregroundColor(.ppTextPrimary)
                Text(String(localized: "categories.stats.expense"))
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: 4) {
                Text("\(archivedCount)")
                    .font(.ppCallout)
                    .fontWeight(.semibold)
                    .foregroundColor(.ppTextPrimary)
                Text(String(localized: "categories.stats.archived"))
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(PPSpacing.md)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func categorySection(_ title: String, categories: [CategoryManagementItem], color: Color) -> some View {
        Group {
            if !categories.isEmpty {
                Section {
                    ForEach(categories) { cat in
                        categoryRow(cat, dimmed: false)
                            .swipeActions(edge: .trailing) {
                                if cat.globalTransactionCount > 0 {
                                    Button {
                                        categoryToArchive = cat
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }
                                    .tint(.ppAmber)
                                } else {
                                    Button(role: .destructive) {
                                        categoryToDelete = cat
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.ppDestructive)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                if !cat.isSystem {
                                    Button { editingCategory = cat } label: { Label("Edit", systemImage: "pencil") }.tint(.ppPrimary)
                                }
                            }
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                    }
                } header: {
                    HStack {
                        Text(title).font(.ppOverline).foregroundColor(.ppTextSecondary).tracking(1)
                        Spacer()
                        Text("\(categories.count)").font(.ppCaption).foregroundColor(.ppTextSecondary)
                    }
                }
            }
        }
    }
    
    private func deleteCategory(_ cat: CategoryManagementItem) async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        do {
            try await appState.apiClient.requestVoid(.deleteCategory(cat.id))
            await load()
        } catch {}
    }

    private func archiveCategory(_ cat: CategoryManagementItem) async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        do {
            try await appState.apiClient.requestVoid(.archiveCategory(cat.id))
            await load()
        } catch {}
    }

    private func categoryRow(_ cat: CategoryManagementItem, dimmed: Bool) -> some View {
        HStack(spacing: PPSpacing.md) {
            Circle()
                .fill(Color(hex: cat.color) ?? .ppPrimary)
                .frame(width: 36, height: 36)
                .overlay(Text(cat.icon).font(.system(size: 16)))
                .opacity(dimmed ? 0.5 : 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(cat.name)
                    .font(.ppHeadline)
                    .foregroundColor(dimmed ? .ppTextTertiary : .ppTextPrimary)

                Text("\(cat.globalTransactionCount) transactions")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextSecondary)
            }

            Spacer()

            if cat.isSystem {
                Text("System")
                    .font(.ppCaption)
                    .foregroundColor(.ppTextTertiary)
                    .padding(.horizontal, PPSpacing.sm)
                    .padding(.vertical, 2)
                    .background(Color.ppSurface)
                    .clipShape(RoundedRectangle(cornerRadius: PPRadius.full))
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: CategoriesManagementResponse = try await appState.apiClient.request(.categoriesManagement)
            incoming = response.incoming
            outgoing = response.outgoing
            archived = response.archived
        } catch {
            errorMessage = String(localized: "Failed to load categories.")
        }
        isLoading = false
    }
}

// Response model
struct CategoriesManagementResponse: Codable {
    let incoming: [CategoryManagementItem]
    let outgoing: [CategoryManagementItem]
    let archived: [CategoryManagementItem]
}

struct CategoryManagementItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let color: String
    let icon: String
    let categoryType: String
    let isArchived: Bool
    let isSystem: Bool
    let globalTransactionCount: Int64
    let budgeted: Int64?
}
