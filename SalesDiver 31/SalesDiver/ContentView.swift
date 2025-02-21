import SwiftUI

struct ContentView: View {
    @State private var selectedMenu: String? = "Companies"
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedMenu: $selectedMenu)
        } content: {
            if selectedMenu == "Companies" {
                CompanyTableView()
            } else {
                Text("Select an option from the menu")
                    .font(.title)
                    .foregroundColor(.gray)
            }
        } detail: {
            EmptyView() // This removes the detail panel entirely
        }
    }
}

struct SidebarView: View {
    @Binding var selectedMenu: String?

    var body: some View {
        List {
            Button(action: { selectedMenu = "Companies" }) {
                Label("Companies", systemImage: "building.2")
            }
            Button(action: { selectedMenu = "Opportunities" }) {
                Label("Opportunities", systemImage: "briefcase")
            }
            Button(action: { selectedMenu = "Meetings" }) {
                Label("Meetings", systemImage: "calendar")
            }
            Button(action: { selectedMenu = "Settings" }) {
                Label("Settings", systemImage: "gear")
            }
        }
        .navigationTitle("SalesDiver")
    }
}
