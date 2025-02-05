import SwiftUI

@main
struct App: SwiftUI.App {
    @StateObject private var worklet = Worklet()
    @StateObject private var ipc = IPC()
    @Environment(\.scenePhase) private var scenePhase
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    worklet.start()
                    
                    if worklet.ipc != nil {
                        ipc.configure(with: worklet.ipc!)
                        ipc.listenForMessages()
                    }
                }
                .onDisappear {
                    worklet.terminate()
                }
        }
        .environmentObject(ipc)
        .modelContainer(for: People.self)
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                worklet.suspend()
            case .active:
                worklet.resume()
            default:
                break
            }
        }
    }
}
