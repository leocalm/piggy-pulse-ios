import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var appState: AppState
    @State private var incoming: [CategoryManagementItem] = []
    @State private var outgoing: [CategoryManagementItem] = []
    @State private var archived: [CategoryManagementItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showArchived = false
    @State private var showAddSheet = false
    @State private var editingCategory: CategoryManagementItem?

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    Section {
                        HStack { Spacer(); ProgressView().tint(.ppTextSecondary); Spacer() }
                            .padding(.vertical, PPSpacing.xxxl)
                            .listRowBackground(Color.ppBackground)
                            .listRowSeparator(.hidden)
                    }
                } else if let error = errorMessage {
                    Section {
                        VStack(spacing: PPSpacing.md) {
                            Image(systemName: "exclamationmark.triangle").font(.system(size: 32)).foregroundColor(.ppAmber)
                            Text(error).font(.ppBody).foregroundColor(.ppTextSecondary)
                            Button("Retry") { Task { await load() } }.font(.ppHeadline).foregroundColor(.ppPrimary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, PPSpacing.xxxl)
                        .listRowBackground(Color.ppBackground).listRowSeparator(.hidden)
                    }
                } else {
                    categorySection("INCOMING", categories: incoming, color: .ppCyan)
                    categorySection("OUTGOING", categories: outgoing, color: .ppPrimary)
                    
                    if !archived.isEmpty {
                        Section {
                            if showArchived {
                                ForEach(archived) { cat in
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
                                        .background(Color.ppCard).cornerRadius(PPRadius.full)
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
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.large)
            .navigationSubtitle("Organize your transactions by type.")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(.white)
                }
            }
        }
    }

    private func categorySection(_ title: String, categories: [CategoryManagementItem], color: Color) -> some View {
        Group {
            if !categories.isEmpty {
                Section {
                    ForEach(categories) { cat in
                        categoryRow(cat, dimmed: false)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await deleteCategory(cat) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.ppDestructive)
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
        do {
            try await appState.apiClient.requestVoid(.deleteCategory(cat.id))
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
                    .cornerRadius(PPRadius.full)
            }
        }
        .padding(PPSpacing.lg)
        .background(Color.ppCard)
        .cornerRadius(PPRadius.md)
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
            errorMessage = "Failed to load categories."
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
}
