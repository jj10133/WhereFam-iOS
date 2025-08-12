//
//  HomeView.swift
//  App
//
//  Created by joker on 2025-01-13.
//

import SwiftUI
import MapLibre
import CoreLocation
import RevenueCat
import RevenueCatUI

struct HomeView: View {
    @EnvironmentObject var ipcViewModel: IPCViewModel
    
    @State private var isPressed = false
    @State private var isSheetPresented: Bool = false
    @State private var selectedOption: MenuOption? = nil
    
    @State private var timer: Timer? = nil
    @State private var showMap: Bool = false
    @State private var isSubscribed: Bool = false
    
    var body: some View {
        ZStack {
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
            checkSubscriptionStatus()
        }
        .onDisappear(perform: stopLocationUpdateTimer)
        .sheet(item: $selectedOption) { option in
            sheetView(for: option)
        }
        .ignoresSafeArea(.all)
    }
    
    //TODO: Change the name or improve the code
    private func onAppear() {
        Task {
            await startHyperswarm()
            startLocationUpdateTimer()
            
            try await Task.sleep(for: .seconds(5))
            getPublicKey()
            joinPeersFromDatabase()
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
        let savedPeople = SQLiteManager.shared.fetchAllPeople()
        
        if !savedPeople.isEmpty {
            Task {
                for member in savedPeople {
                    let message: [String: Any] = [
                        "action": "joinPeer",
                        "data": member.id
                    ]
                    
                    await ipcViewModel.writeToIPC(message: message)
                }
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
                await ipcViewModel.writeToIPC(message: message)
            }
        }
    }
    
    private func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            if let error = error {
                print("Error fetching customer info: \(error.localizedDescription)")
                return
            }
            
            if let customerInfo = customerInfo {
                self.isSubscribed = customerInfo.entitlements["Tip"]?.isActive == true
            }
        }
    }
    
    @ViewBuilder
    private func sheetView(for option: MenuOption) -> some View {
        switch option {
        case .people:
            PeopleView()
        case .shareID:
            ShareIDView()
            // case .provideFeedback:
            //     return AnyView(ProvideFeedbackView())
        case .support:
            if isSubscribed {
                ThanksView()
            } else {
                PaywallView()
            }
        }
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
    
    HomeView()
        .environmentObject(IPCViewModel())
}
