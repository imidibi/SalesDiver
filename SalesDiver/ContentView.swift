import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                WaterBackgroundView() // ✅ Added Water Background
                VStack(spacing: 40) {
                    Text("SalesDiver Dashboard")
                        .font(.largeTitle)
                        .bold()
                    
                    GridView()

                    Spacer()
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .imageScale(.large)
                                .padding(5)
                        }
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Water Background View
struct WaterBackgroundView: View {
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.7)]),
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all)
            .overlay(
                WaveShape()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 200)
                    .offset(y: -50), alignment: .top
            )
    }
}

// MARK: - Wave Shape
struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.7))
        path.addCurve(to: CGPoint(x: width, y: height * 0.7),
                      control1: CGPoint(x: width * 0.25, y: height * 0.5),
                      control2: CGPoint(x: width * 0.75, y: height * 0.9))
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Grid Menu View
struct GridView: View {
    let menuItems: [(name: String, icon: String, destination: AnyView)] = [
        ("Company Data", "building.2.fill", AnyView(CompanyDataView())),
        ("Product Data", "cart.fill", AnyView(ProductDataView())),
        ("Opportunities", "chart.bar.fill", AnyView(OpportunityDataView())),
        ("Contacts", "person.2.fill", AnyView(ContactsView())),
        ("Meetings", "calendar.badge.clock", AnyView(MeetingsView())),
        ("Follow Ups", "checkmark.circle.fill", AnyView(FollowUpsView())),
        ("Security Assessment", "shield.fill", AnyView(SecurityAssessmentView())),
        ("Questions", "questionmark.circle.fill", AnyView(QuestionsView())),
        ("Assessments", "doc.text.magnifyingglass", AnyView(AssessmentView().environmentObject(CoreDataManager.shared))) // Injected CoreDataManager
    ]

    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 40) {
            ForEach(menuItems, id: \.name) { item in
                NavigationLink(destination: item.destination) {
                    VStack {
                        Image(systemName: item.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)

                        Text(item.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(width: 180, height: 180)
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                }
            }
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
