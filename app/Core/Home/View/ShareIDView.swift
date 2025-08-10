//
//  ShareIDView.swift
//  App
//
//  Created by joker on 2025-01-16.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct ShareIDView: View {
    @EnvironmentObject var ipcViewModel: IPCViewModel
    @State private var qrCodeImage: UIImage?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                qrCodeSection
                copyPublicKeySection
                
            }
            .navigationTitle("Share Your ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
        }
        .onAppear {
            getPublicKey()
            generateQRCode(from: ipcViewModel.publicKey)
        }
        .onChange(of: ipcViewModel.publicKey) { oldValue, newValue in
            generateQRCode(from: oldValue.isEmpty ? newValue : oldValue)
        }
        .if(UIDevice.current.userInterfaceIdiom == .phone) { view in
            view.presentationDetents([.medium])
        }
        .presentationDragIndicator(.visible)
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
    
    private func generateQRCode(from string: String) {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        let data = string.data(using: .utf8)
        
        filter.setValue(data, forKey: "inputMessage")
        
        if let outputImage = filter.outputImage {
            let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
            qrCodeImage = UIImage(cgImage: cgImage!)
        }
    }
    
    private var qrCodeSection: some View {
        Group {
            if let qrImage = qrCodeImage {
                VStack {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
            }
        }
    }
    
    private var copyPublicKeySection: some View {
        Group {
            Text("Or copy public ID")
                .foregroundStyle(.secondary)
            
            if !ipcViewModel.publicKey.isEmpty {
                HStack {
                    Text(ipcViewModel.publicKey)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .lineLimit(1)
                    
                    copyButton
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var copyButton: some View {
        Button(action: {
            UIPasteboard.general.string = ipcViewModel.publicKey
        }) {
            Image(systemName: "doc.on.clipboard")
                .foregroundColor(.blue)
                .padding(10)
                .background(.gray.opacity(0.1))
                .clipShape(Circle())
        }
        .accessibilityLabel("Copy Public Key")
    }
    
    private var toolbarContent: some View {
        Group {
            if let image = qrCodeImage {
                let shareImage = Image(uiImage: image)
                ShareLink(item: shareImage, preview: SharePreview("Share ID to Friends", image: shareImage)) {
                    Label("Share QR Code", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.blue)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
}

#Preview {
    ShareIDView()
        .environmentObject(IPCViewModel())
}
