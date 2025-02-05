//
//  ShareIDView.swift
//  App
//
//  Created by joker on 2025-01-16.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ShareIDView: View {
    @EnvironmentObject var ipc: IPC
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
            generateQRCode(from: ipc.publicKey)
        }
        .onChange(of: ipc.publicKey) { oldValue, newValue in
            generateQRCode(from: oldValue.isEmpty ? newValue : oldValue)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
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
            
            if !ipc.publicKey.isEmpty {
                HStack {
                    Text(ipc.publicKey)
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
            UIPasteboard.general.string = ipc.publicKey
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
        .environmentObject(IPC())
}
