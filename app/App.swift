import BareKit
import SwiftUI

@main
struct App: SwiftUI.App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var worker = Worker()
    @StateObject private var ipcViewModel = IPCViewModel()
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    worker.start()
                    ipcViewModel.configure(with: worker.ipc, modelContext: modelContext)
                    Task {
                        await ipcViewModel.readFromIPC()
                    }
                }
                .onDisappear {
                    worker.terminate()
                }
        }
        .environmentObject(ipcViewModel)
        .modelContainer(for: People.self)
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                worker.suspend()
            case .active:
                worker.resume()
            default:
                break
            }
        }
    }
    
    private func requestPushNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("\(error.localizedDescription)")
            } else if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification authorization denied")
            }
        }
    }
}
