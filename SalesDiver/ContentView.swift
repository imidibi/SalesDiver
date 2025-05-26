import SwiftUI
import CoreData
// No import needed — just ensure FollowUpsView.swift is in the same target

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
                        NavigationLink(destination: HelpView()) {
                            Image(systemName: "questionmark.circle")
                                .imageScale(.large)
                                .padding(5)
                        }
                    }
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
        ("Companies", "building.2.fill", AnyView(CompanyDataView())),
        ("Services", "desktopcomputer", AnyView(ProductDataView())),
        ("Opportunities", "chart.bar.fill", AnyView(OpportunityDataView())),
        ("Contacts", "person.2.fill", AnyView(ContactsView())),
        ("Meetings", "calendar.badge.clock", AnyView(ViewMeetingsView())),
        ("Follow Ups", "checkmark.circle.fill", AnyView(FollowUpsView())),
        ("Security Review", "shield.fill", AnyView(SecurityAssessmentView())),
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

// MARK: - Help View
struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Welcome to SalesDiver!")
                    .font(.title)
                    .bold()
                Text("Our goal is to help you dive into your sales pipeline and to help you qualify and close the treasure therein!")

                Text("SalesDiver is based on the new or existing companies you want to sell to, the contacts in those companies you will meet and interact with, the services you plan to sell to them, all wrapped up in the opportunities you hope to close.")

                Text("The odds of closing those opportunities increase the better you qualify those opportunities. Qualification is achieved by asking questions to better understand your position. SalesDiver therefore allows you to create a customized list of questions to ask in your sales meetings to ensure you really understand where you stand.")

                Text("Qualification is important in not only reflecting where you are, but also in helping you build an action plan to increase your chances of closing the deal. It offers three methodologies, with differing levels of complexity and thoroughness. Those methodologies are:")

                Group {
                    Text("• BANT – Budget, Authority, Need and Timescale")
                    Text("• MEDDIC – Metrics, Economic Buyer, Decision Maker, Decision Process, Identify Pain, Champion")
                    Text("• SCUBATANK – Solution, Competition, Uniques, Benefits, Authority, Timescale, Action Plan, Need and Kash.")
                }.padding(.leading)

                Text("The first two are industry standard methodologies and the third is a SalesDiver special! Please select your preferred methodology in settings (the gear icon).")

                Text("• BANT is very effective for opportunities that have a short deal cycle and which are not overly complex from a decision structure. It is used extensively by SDR’s in the SaaS software and online selling marketplace as it hits to the heart of the matter.")

                Text("• MEDDIC is very good for larger deals with a more complex decision structure and is oriented to digging deep into client pain, identifying it and structuring the proposal around relieving that pain.")

                Text("• SCUBATANK is a further level of refinement and is focused on more competitive deals where understanding the competition, articulating your unique capabilities and benefits, and engaging the client as much as possible through an action plan can drive differentiation.")

                Text("SalesDiver offers an icon for each element in these methodologies to allow you to track your progress on each deal. All red shows a totally unqualified deal whereas all green is a deal you should win!")

                Text("The icons for each qualification area can be red for unqualified, yellow if you are making progress but not yet fully satisfied, and green if you are confident in that item. Be honest and track your progress towards more successfully closed deals.")

                Text("Happy Salesdiving!")
                    .font(.headline)
                    .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Help")
    }
}
