//
//  AboutView.swift
//  App
//
//  Created by joker on 2025-08-29.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Link(
                        destination: URL(string: "https://wherefam.com/privacy.html")!
                    ) {
                        Label("Privacy Policy", systemImage: "lock")
                    }
                    
                    Link(
                        destination: URL(string: "https://wherefam.com/terms.html")!
                    ) {
                        Label("Terms of Use", systemImage: "checkmark.shield")
                    }
                }
            }
            .navigationTitle("WhereFam")
        }
    }
}

#Preview {
    AboutView()
}
