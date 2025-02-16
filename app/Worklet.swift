//
//  Worklet.swift
//  App
//
//  Created by joker on 2025-01-30.
//


class Worklet: ObservableObject {
    private var worklet: BareWorklet?
    public var ipc: BareIPC?
    
    
    func start() {
        worklet = BareWorklet(configuration: nil)
        
        worklet?.start("app", ofType: "bundle", arguments: [])
        
        if let worklet = worklet {
            ipc = BareIPC(worklet: worklet)
        }
    }
    
    func suspend() {
//        worklet?.suspend()
    }
    
    func resume() {
        worklet?.resume()
    }
    
    func terminate() {
        worklet?.terminate()
    }
    
}

extension BareIPC {
    func writeAsync(_ data: Data) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            let success = self.write(data)
            if success {
                continuation.resume(returning: true)
                return
            }
            
            self.writable = { ipc in
                let success = ipc.write(data)
                if success {
                    self.writable = nil
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    func readStream() -> AsyncStream<Data> {
        return AsyncStream { continuation in
            if let data = self.read() {
                continuation.yield(data)
            }
            
            self.readable = { ipc in
                while let data = ipc.read() {
                    continuation.yield(data)
                }
            }
        }
    }
}
