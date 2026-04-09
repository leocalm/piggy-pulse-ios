import SwiftUI
import TipKit

struct CategoriesView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeManager) private var theme
    
    @State private var incoming: [CategoryManagementItem] = []
    @State private var outgoing: [CategoryManagementItem] = []
    @State private var archived: [CategoryManagementItem] = []
    @State private var overviewMap: [UUID: CategoriesOverviewSummaryItem] = [:]
    @State private var overviewSummary: CategoriesOverviewSummary?
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

                if isLoading {
                    Section {
                        HStack { Spacer(); ProgressView().tint(.ppTextSecondary); Spacer() }
                            .padding(.vertical, PPSpacing.xxxl)
                            .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                    }
                } else if let error = errorMessage {
                    Section {
                        VStack(spacing: PPSpacing.md) {
                            Image(systemName: "exclamationmark.triangle").font(.system(size: 32)).foregroundColor(theme.secondary)
                            Text(error).font(.ppBody).foregroundColor(.ppTextSecondary)
                            Button(String(localized: "common.retry")) { Task { await load() } }.font(.ppHeadline).foregroundColor(theme.primary)
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
                    if isWideLayout {
                        // Wide layout: incoming and outgoing side by side
                        Section {
                            HStack(alignment: .top, spacing: PPSpacing.lg) {
                                // Incoming column
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    HStack {
                                        Text(String(localized: "INCOMING")).font(.ppOverline).foregroundColor(.ppTextSecondary).tracking(1)
                                        Spacer()
                                        Text("\(filteredIncoming.count)").font(.ppCaption).foregroundColor(.ppTextSecondary)
                                    }
                                    ForEach(filteredIncoming) { cat in
                                        categoryRow(cat, dimmed: false)
                                            .contextMenu {
                                                categoryContextMenu(cat)
                                            }
                                    }
                                    if filteredIncoming.isEmpty {
                                        Text(String(localized: "common.none"))
                                            .font(.ppCaption)
                                            .foregroundColor(.ppTextTertiary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, PPSpacing.lg)
                                    }
                                }
                                .frame(maxWidth: .infinity)

                                // Outgoing column
                                VStack(alignment: .leading, spacing: PPSpacing.sm) {
                                    HStack {
                                        Text(String(localized: "OUTGOING")).font(.ppOverline).foregroundColor(.ppTextSecondary).tracking(1)
                                        Spacer()
                                        Text("\(filteredOutgoing.count)").font(.ppCaption).foregroundColor(.ppTextSecondary)
                                    }
                                    ForEach(filteredOutgoing) { cat in
                                        categoryRow(cat, dimmed: false)
                                            .contextMenu {
                                                categoryContextMenu(cat)
                                            }
                                    }
                                    if filteredOutgoing.isEmpty {
                                        Text(String(localized: "common.none"))
                                            .font(.ppCaption)
                                            .foregroundColor(.ppTextTertiary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, PPSpacing.lg)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: PPSpacing.xs, leading: PPSpacing.lg, bottom: PPSpacing.xs, trailing: PPSpacing.lg))
                        }
                    } else {
                        // Compact layout: stacked sections
                        categorySection(String(localized: "INCOMING"), categories: filteredIncoming, color: theme.tertiary)
                        categorySection(String(localized: "OUTGOING"), categories: filteredOutgoing, color: theme.primary)
                    }

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
                                    Text(String(localized: "common.archived").uppercased()).font(.ppOverline).foregroundColor(.ppTextSecondary).tracking(1)
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
            .refreshable { await Task { @MainActor in await self.load() }.value }
            .task { await load() }
            .sheet(isPresented: $showAddSheet, onDismiss: { Task { await load() } }) {
                AddCategorySheet { }.environmentObject(appState)
            }
            .sheet(item: $editingCategory) { cat in
                EditCategorySheet(category: cat, apiClient: appState.apiClient, currentTarget: overviewMap[cat.id]?.budgeted) { Task { await load() } }
                    .environmentObject(appState)
            }
            .confirmationDialog("Archive \"\(categoryToArchive?.name ?? "")\"?", isPresented: Binding(get: { categoryToArchive != nil }, set: { if !$0 { categoryToArchive = nil } }), titleVisibility: .visible) {
                Button(String(localized: "common.archive"), role: .destructive) {
                    if let cat = categoryToArchive { Task { await archiveCategory(cat) } }
                }
                Button(String(localized: "common.cancel"), role: .cancel) { categoryToArchive = nil }
            } message: {
                Text(String(localized: "categories.archive.message"))
            }
            .confirmationDialog("Delete \"\(categoryToDelete?.name ?? "")\"?", isPresented: Binding(get: { categoryToDelete != nil }, set: { if !$0 { categoryToDelete = nil } }), titleVisibility: .visible) {
                Button(String(localized: "common.delete"), role: .destructive) {
                    if let cat = categoryToDelete { Task { await deleteCategory(cat) } }
                }
                Button(String(localized: "common.cancel"), role: .cancel) { categoryToDelete = nil }
            } message: {
                Text(String(localized: "categories.delete.message"))
            }
            .navigationTitle(String(localized: "more.categories"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("categories-add-button")
                }
            }

    }

    @Environment(\.isWideLayout) private var isWideLayout

    private var categoryStatsBar: some View {
        let allActive = incoming + outgoing
        let totalCount = allActive.count
        // Only count unbudgeted when overview data has loaded
        let unbudgetedCount = overviewMap.isEmpty ? 0 : allActive.filter { overviewMap[$0.id]?.budgeted == nil || overviewMap[$0.id]?.budgeted == 0 }.count

        let items: [(String, String)] = [
            (String(localized: "categories.summary.expenseBudget"),
             overviewSummary.map { formatCurrency($0.totalBudgeted ?? 0, code: appState.currencyCode) } ?? "—"),
            (String(localized: "categories.summary.incomeTarget"),
             overviewSummary.map { s in
                 s.totalBudgetedIncoming.map { formatCurrency($0, code: appState.currencyCode) } ?? "—"
             } ?? "—"),
            (String(localized: "categories.summary.totalSpent"),
             overviewSummary.map { formatCurrency($0.totalSpent, code: appState.currencyCode) } ?? "—"),
            (String(localized: "categories.summary.categories"),
             "\(totalCount)"),
            (String(localized: "categories.summary.unbudgeted"),
             "\(unbudgetedCount)")
        ]

        return Group {
            if isWideLayout {
                // Wide: 3-column grid for stats
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: PPSpacing.sm), count: 3), spacing: PPSpacing.sm) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        summaryGridCell(label: item.0, value: item.1)
                    }
                }
                .padding(PPSpacing.md)
                .background(Color.ppCard)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
            } else {
                // Compact: vertical stack with dividers
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        if index > 0 {
                            Divider().background(Color.ppBorder)
                        }
                        summaryRow(label: item.0, value: item.1)
                    }
                }
                .background(Color.ppCard)
                .clipShape(RoundedRectangle(cornerRadius: PPRadius.lg))
                .overlay(RoundedRectangle(cornerRadius: PPRadius.lg).stroke(Color.ppBorder, lineWidth: 1))
            }
        }
    }

    private func summaryGridCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.xs) {
            Text(label.uppercased())
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)
            Text(value)
                .font(.ppHeadline)
                .foregroundColor(.ppTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PPSpacing.md)
        .background(Color.ppSurface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
    }

    private func summaryRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.xs) {
            Text(label.uppercased())
                .font(.ppOverline)
                .foregroundColor(.ppTextSecondary)
                .tracking(1)
            Text(value)
                .font(.ppHeadline)
                .foregroundColor(.ppTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PPSpacing.lg)
        .padding(.vertical, PPSpacing.md)
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
                                        Label(String(localized: "common.archive"), systemImage: "archivebox")
                                    }
                                    .tint(theme.secondary)
                                } else {
                                    Button(role: .destructive) {
                                        categoryToDelete = cat
                                    } label: {
                                        Label(String(localized: "common.delete"), systemImage: "trash")
                                    }
                                    .tint(.ppDestructive)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                if !cat.isSystem {
                                    Button { editingCategory = cat } label: { Label(String(localized: "common.edit"), systemImage: "pencil") }.tint(theme.primary)
                                }
                            }
                            .contextMenu {
                                if !cat.isSystem {
                                    Button {
                                        editingCategory = cat
                                    } label: {
                                        Label(String(localized: "common.edit"), systemImage: "pencil")
                                    }
                                }
                                if cat.globalTransactionCount > 0 {
                                    Button {
                                        categoryToArchive = cat
                                    } label: {
                                        Label(String(localized: "common.archive"), systemImage: "archivebox")
                                    }
                                } else {
                                    Button(role: .destructive) {
                                        categoryToDelete = cat
                                    } label: {
                                        Label(String(localized: "common.delete"), systemImage: "trash")
                                    }
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
    
    @ViewBuilder
    private func categoryContextMenu(_ cat: CategoryManagementItem) -> some View {
        if !cat.isSystem {
            Button {
                editingCategory = cat
            } label: {
                Label(String(localized: "common.edit"), systemImage: "pencil")
            }
        }
        if cat.globalTransactionCount > 0 {
            Button {
                categoryToArchive = cat
            } label: {
                Label(String(localized: "common.archive"), systemImage: "archivebox")
            }
        } else {
            Button(role: .destructive) {
                categoryToDelete = cat
            } label: {
                Label(String(localized: "common.delete"), systemImage: "trash")
            }
        }
    }

    private func deleteCategory(_ cat: CategoryManagementItem) async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        do {
            try await appState.apiClient.requestVoid(.deleteCategory(cat.id))
            await load()
        } catch {
            errorMessage = String(localized: "categories.delete.failed")
        }
    }

    private func archiveCategory(_ cat: CategoryManagementItem) async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        do {
            try await appState.apiClient.requestVoid(.archiveCategory(cat.id))
            await load()
        } catch {
            errorMessage = String(localized: "categories.archive.failed")
        }
    }

    private func categoryRow(_ cat: CategoryManagementItem, dimmed: Bool) -> some View {
        HStack(spacing: PPSpacing.md) {
            Circle()
                .fill(Color(hex: cat.color) ?? theme.primary)
                .frame(width: 36, height: 36)
                .overlay(Text(cat.icon).font(.system(size: 16)))
                .opacity(dimmed ? 0.5 : 1)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: PPSpacing.sm) {
                    Text(cat.name)
                        .font(.ppHeadline)
                        .foregroundColor(dimmed ? .ppTextTertiary : .ppTextPrimary)

                    if let behavior = cat.behavior, !behavior.isEmpty {
                        Text(behaviorLabel(behavior).uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(behaviorColor(behavior))
                            .padding(.horizontal, PPSpacing.sm)
                            .padding(.vertical, 2)
                            .background(behaviorColor(behavior).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: PPRadius.sm))
                    }
                }

                let overview = overviewMap[cat.id]
                let typeLabel = cat.type == "income" ? String(localized: "common.incoming") : String(localized: "common.outgoing")
                if let budgeted = overview?.budgeted, budgeted > 0 {
                    Text("\(typeLabel) · \(formatCurrency(budgeted, code: appState.currencyCode)) \(String(localized: "categories.budgetedLabel"))")
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                } else {
                    Text(typeLabel)
                        .font(.ppCaption)
                        .foregroundColor(.ppTextSecondary)
                }
            }

            Spacer()

            // Spent amount
            if let overview = overviewMap[cat.id] {
                Text(formatCurrency(overview.actual, code: appState.currencyCode))
                    .font(.ppCallout)
                    .fontDesign(.monospaced)
                    .foregroundColor(.ppTextPrimary)
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .clipShape(RoundedRectangle(cornerRadius: PPRadius.md))
        .overlay(RoundedRectangle(cornerRadius: PPRadius.md).stroke(Color.ppBorder, lineWidth: 1))
    }

    private func behaviorLabel(_ behavior: String) -> String {
        switch behavior {
        case "fixed": return String(localized: "category.behavior.fixed")
        case "variable": return String(localized: "category.behavior.variable")
        case "subscription": return String(localized: "category.behavior.subscription")
        default: return behavior
        }
    }

    private func behaviorColor(_ behavior: String) -> Color {
        switch behavior {
        case "fixed": return theme.secondary
        case "variable": return .ppTeal
        case "subscription": return theme.tertiary
        default: return .ppTextSecondary
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: CategoriesManagementResponse = try await appState.apiClient.request(.categoriesManagement)
            incoming = response.incoming
            outgoing = response.outgoing
            archived = response.archived

            // Load overview for spent/budgeted data
            if let periodId = appState.selectedPeriod?.id {
                if let overview: CategoriesOverviewResponse = try? await appState.apiClient.request(
                    .categoriesOverview,
                    queryItems: [URLQueryItem(name: "periodId", value: periodId.uuidString)]
                ) {
                    overviewMap = Dictionary(uniqueKeysWithValues: overview.categories.map { ($0.id, $0) })
                    overviewSummary = overview.summary
                }
            }
        } catch {
            errorMessage = String(localized: "Failed to load categories.")
        }
        isLoading = false
    }
}

// Response model
struct CategoriesManagementResponse: Codable {
    let data: [CategoryManagementItem]
    let totalCount: Int?
    let hasMore: Bool?
    let nextCursor: String?

    var incoming: [CategoryManagementItem] { data.filter { !$0.isArchived && $0.type.lowercased() == "income" } }
    var outgoing: [CategoryManagementItem] { data.filter { !$0.isArchived && $0.type.lowercased() == "expense" } }
    var archived: [CategoryManagementItem] { data.filter { $0.isArchived } }
}

struct CategoryManagementItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let color: String
    let icon: String
    let type: String               // "income" | "expense" | "transfer"
    let status: String             // "active" | "inactive"
    let parentId: UUID?
    let behavior: String?          // "fixed" | "variable" | "subscription" | nil
    let description: String?
    let numberOfTransactions: Int64

    // MARK: - Backward compatibility
    var categoryType: String { type }
    var isArchived: Bool { status == "inactive" }
    var isSystem: Bool { false }
    var globalTransactionCount: Int64 { numberOfTransactions }
    var budgeted: Int64? { nil }   // Not in v2 CategoryManagementListItem
}
