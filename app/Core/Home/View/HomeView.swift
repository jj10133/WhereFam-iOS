//
//  HomeView.swift
//  App
//
//  Created by joker on 2025-01-13.
//

import SwiftUI
import SwiftData
import MapLibre
import MapLibreSwiftUI
import MapLibreSwiftDSL
import CoreLocation
import RevenueCat
import RevenueCatUI

struct HomeView: View {
    @EnvironmentObject var ipcViewModel: IPCViewModel
    @Environment(\.modelContext) private var modelContext
    @Query var people: [People]
    
    @State private var isPressed = false
    @State private var isSheetPresented: Bool = false
    @State private var selectedOption: MenuOption? = nil
    
    @State private var timer: Timer? = nil
    @State private var showMap: Bool = false
    
    private let appUrl = "https://app.com"
    
    @State var camera = MapViewCamera.trackUserLocation()
    
    var body: some View {
        ZStack {
//            if showMap {
//                MyMapView(position: $camera)
//            } else {
//                ProgressView()
//            }
            SimpleMapView()
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    MenuButton(isPressed: $isPressed, selectedOption: $selectedOption, isSheetPresented: $isSheetPresented)
                }
            }
        }
        .onAppear {
            onAppear()
            LocationManager.shared.requestLocation()
        }
        .onDisappear(perform: stopLocationUpdateTimer)
        .task {
            joinPeersFromDatabase()
        }
        .sheet(item: $selectedOption) { option in
            sheetView(for: option)
        }
        .ignoresSafeArea(.all)
    }
    
    //TODO: Change the name or improve the code
    private func onAppear() {
        Task {
            await startHyperswarm()
            ipcViewModel.modelContext = modelContext
            startLocationUpdateTimer()
            
//            try await Task.sleep(for: .seconds(5))
//            await MainActor.run {
//                self.showMap = true
//            }
        }
    }
    
    private func startHyperswarm() async {
        let directory = URL.documentsDirectory
        let message: [String: Any] = [
            "action": "start",
            "data": [
                "path" : directory.path()
            ]
        ]
        await ipcViewModel.writeToIPC(message: message)
    }
    
    // TODO: Use AsynSequence rather than this timer lol!!
    private func startLocationUpdateTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            sendUserLocation()
        }
    }
    
    private func stopLocationUpdateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func joinPeersFromDatabase() {
        Task {
            for member in people {
                let message: [String: Any] = [
                    "action": "joinPeer",
                    "data": member.id
                ]
                
                print(member.id)
                await ipcViewModel.writeToIPC(message: message)
            }
        }
    }
    
    private func sendUserLocation() {
        Task {
            if let location = LocationManager.shared.userLocation {
                let message: [String: Any] = [
                    "action": "locationUpdate",
                    "data": [
                        "id": ipcViewModel.publicKey,
                        "name": UserDefaults.standard.string(forKey: "userName") ?? "nil",
                        "latitude": location.coordinate.latitude,
                        "longitude": location.coordinate.longitude
                    ]
                ]
                print("Sending location update")
                await ipcViewModel.writeToIPC(message: message)
            }
        }
    }
    
    private func sheetView(for option: MenuOption) -> some View {
        switch option {
        case .people:
            return AnyView(PeopleView())
        case .shareID:
            return AnyView(ShareIDView())
        // case .provideFeedback:
        //     return AnyView(ProvideFeedbackView())
        case .support:
            return AnyView(PaywallView())
            
        }
    }
}

struct MyMapView: View {
    @EnvironmentObject var ipcViewModel: IPCViewModel
    @Binding var position: MapViewCamera
    @State var styleURL: URL = Bundle.main.url(forResource: "style", withExtension: "json")!
    
    var body: some View {
        MapView(styleURL: styleURL, camera: $position) {
            let allLocationsSource = ShapeSource(identifier: "all-locations") {
                for person in ipcViewModel.updatedPeopleLocation.values {
                    if let lat = person.latitude, let lng = person.longitude {
                        MLNPointFeature(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)) { feature in
                            feature.attributes["name"] = person.name
                        }
                    }
                }
            }
            
            SymbolStyleLayer(identifier: "people-pins", source: allLocationsSource)
                    .iconImage(UIImage(systemName: "person.fill")!)
                    
        }
    }
}

struct PersonAnnotationView: View {
    var person: LocationUpdates
    
    var body: some View {
        VStack(spacing: 5) {
            Circle()
                .frame(width: 40, height: 40)
                .foregroundColor(Color.blue)
                .overlay(Text(person.name?.prefix(1) ?? "?")
                    .font(.headline)
                    .foregroundColor(.white))
            
            Text(person.name ?? "")
                .font(.caption)
                .foregroundColor(.white)
                .padding(5)
                .background(Color.blue.opacity(0.8), in: Capsule())
                .shadow(radius: 3)
                .scaleEffect(0.9)
        }
        .padding(5)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
    }
}

struct MenuButton: View {
    @Binding var isPressed: Bool
    @Binding var selectedOption: MenuOption?
    @Binding var isSheetPresented: Bool
    
    var body: some View {
        Menu {
            Button(action: { openSheet(.people) }) {
                Label("People", systemImage: "person.circle")
            }
            
            Button(action: { openSheet(.shareID) }) {
                Label("Share Your ID", systemImage: "qrcode")
            }
            
            // Button(action: { openSheet(.provideFeedback) }) {
            //     Label("Provide Feedback", systemImage: "exclamationmark.bubble")
            // }
            
            Button(action: { openSheet(.support) }) {
                Label("Support App", systemImage: "wand.and.stars")
            }
            
            ShareLink(item: "https://wherefam.com") {
                Label("Refer To Friend", systemImage: "square.and.arrow.up")
            }
            
            if let reviewURL = URL(string: "https://apps.apple.com/app/id6749550634?action=write-review") {
                Link(destination: reviewURL) {
                    Label("Rate App", systemImage: "link")
                }
            }
            
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 33))
                .foregroundColor(.blue)
                .padding()
                .background(Circle().fill(Color(UIColor.systemBackground)).shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5))
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(), value: isPressed)
        }
        .padding()
    }
    
    private func openSheet(_ option: MenuOption) {
        selectedOption = option
        isSheetPresented.toggle()
    }
}

enum MenuOption: Identifiable {
    case people, shareID, support
    
    var id: String {
        switch self {
        case .people:
            return "people"
        case .shareID:
            return "shareID"
        // case .provideFeedback:
        //     return "provideFeedback"
        case .support:
            return "support"
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: People.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    HomeView()
        .environmentObject(IPCViewModel())
        .modelContainer(container)
}
