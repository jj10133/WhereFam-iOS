//
//  HomeView.swift
//  App
//
//  Created by joker on 2025-01-13.
//

import SwiftUI
import SwiftData
import MapKit

struct HomeView: View {
    @EnvironmentObject var ipcViewModel: IPCViewModel
    @Environment(\.modelContext) private var modelContext
    @Query var people: [People]
    
    @Namespace private var mapScope
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    
    @State private var isPressed = false
    @State private var isSheetPresented: Bool = false
    @State private var selectedOption: MenuOption? = nil
    
    @State private var timer: Timer? = nil
    
    private let appUrl = "https://app.com"
    
    var body: some View {
        ZStack {
            MapView(position: $position, mapScope: mapScope)
            
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
            //joinPeersFromDatabase() // Uncomment if needed
        }
        .sheet(item: $selectedOption) { option in
            sheetView(for: option)
        }
    }
    
    private func onAppear() {
        Task {
            await startHyperswarm()
            getPublicKey()
            ipcViewModel.modelContext = modelContext
            startLocationUpdateTimer()
        }
    }
    
    private func startHyperswarm() async {
        let directory = URL.documentsDirectory
        let message: [String: Any] = [
            "action": "startHyperswarm",
            "data": directory.path()
        ]
        await ipcViewModel.writeToIPC(message: message)
    }
    
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
            let message: [String: Any] = [
                "action": "locationUpdate",
                "data": [
                    "id": ipcViewModel.publicKey,
                    "name": UserDefaults.standard.string(forKey: "userName") ?? "",
                    "latitude": LocationManager.shared.userLocation?.coordinate.latitude,
                    "longitude": LocationManager.shared.userLocation?.coordinate.longitude
                ]
            ]
            print("Sending location update")
            await ipcViewModel.writeToIPC(message: message)
        }
    }
    
    private func getPublicKey() {
        Task {
            if ipcViewModel.publicKey.isEmpty {
                let message: [String: Any] = [
                    "action": "requestPublicKey",
                    "data": [:]
                ]
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
        case .provideFeedback:
            return AnyView(ProvideFeedbackView())
        }
    }
}

struct MapView: View {
    @EnvironmentObject var ipc: IPCViewModel
    @Binding var position: MapCameraPosition
    var mapScope: Namespace.ID
    
    var body: some View {
        Map(position: $position, interactionModes: [.all], scope: mapScope) {
            UserAnnotation()
            
            ForEach(Array(ipc.updatedPeopleLocation.values)) { person in
                if let lat = person.latitude, let lng = person.longitude {
                    Annotation(person.name ?? "", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng), anchor: .bottom) {
                        PersonAnnotationView(person: person)
                    }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
            MapPitchToggle()
        }
        .mapScope(mapScope)
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
            
            Button(action: { openSheet(.provideFeedback) }) {
                Label("Provide Feedback", systemImage: "exclamationmark.bubble")
            }
            
            ShareLink(item: "https://app.com") {
                Label("Refer To Friend", systemImage: "square.and.arrow.up")
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
    case people, shareID, provideFeedback
    
    var id: String {
        switch self {
        case .people:
            return "people"
        case .shareID:
            return "shareID"
        case .provideFeedback:
            return "provideFeedback"
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(IPCViewModel())
}
